/**
 * @title Bonds
 * @dev ERC721 based bond system with tiered interest rates and epoch-based accrual.
 * @author Akram Mohammed - The Forge
 *
 * THIS CONTRACT IS A PROOF OF CONCEPT AND IS DUE TO BE ITERATED UPON!
 * This contract manages a bond system where each bond is associated with a tier that defines its interest rate,
 * supply, and price. The system operates on epochs, which are fixed time durations for interest accrual.
 * Bonds earn interest composed of a static rate, set during minting per tier, and a dynamic rate based
 * on the holder's bond quantity. Key features include bond minting subject to tier supply, dynamic interest accrual,
 * disqualification penalties for bond transfer, and administrative controls for whitelisting and management.
 * The contract uses OpenZeppelin's ERC20 and SafeMath libraries for enhanced security and functionality.
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;
import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./BondBase.sol";

using SafeMath for uint256;
using SafeERC20 for IERC20;

/**
 * @title Bonds
 * @dev An ERC721 based bond contract with varying interest tiers and special functionalities.
 */
contract Bonds is BondBase {
    constructor(
        address _superAdmin,
        address _vault,
        uint256 _maxEpoch,
        uint256 _endEpoch
    ) BondBase(_superAdmin, _vault, _maxEpoch, _endEpoch) {}

    /**
     * @dev Metadata URL for all bonds.
     */
    string private constant METADATA_URL =
        "https://ipfs.io/ipfs/QmQS1m3JmJwL8KCrXnu4cRgzp1T7HJmN9d22cKajnJo9uA";

    /**
        @dev allows admins to toggle whitelisted memebers.
        * 
        @param _account the address to be whitelisted
        */
    function toggleWhitelist(address _account) external onlyAdmin {
        whitelist[_account] = !whitelist[_account];
        emit WhitelistToggled(_account);
    }

    /**
     * @dev Batch adds addresses to the whitelist.
     * This function should be restricted to only be callable by an admin.
     *
     * @notice This function is not gas efficient and should only be used if necessary.
     * @param addresses Array of addresses to be whitelisted.
     */
    function addBatchToWhitelist(
        address[] memory addresses
    ) external onlyAdmin {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
            emit WhitelistToggled(addresses[i]);
        }
    }

    /**
    @dev Internal function to disqualify a bonds for a certain number of epochs.
    *
    @param tokenId the id of the bond
    @param epochs the number of epochs to be disqualified
    */
    function disqualifyForEpochs(
        uint256 tokenId,
        uint256 epochs
    ) internal override {
        Bond storage bond = bondData[tokenId];
        bond.disqualifiedUntilEpoch = getCurrentEpoch() + epochs;
        bond.disqualifiedEpochCount = epochs;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Check if the token is being minted (from is the zero address)
        if (from != address(0)) {
            disqualifyForEpochs(tokenId, 1);
        }
    }

    /**
        @dev allows for the minting of bonds.
        * 
        @param _value the value of the bond
        @param _contractAddress the address of the currency
        
        */
    function mintBond(
        uint256 _value,
        address _contractAddress
    )
        public
        payable
        override
        currencyWhitelisted(_contractAddress)
        onlyWhitelisted
        notPaused
    {
        require(
            currencies[_contractAddress].totalMinted.add(_value) <=
                currencies[_contractAddress].maximumSupply,
            "Maximum supply reached"
        );
        require(
            bondValueMinted[msg.sender][_contractAddress].add(_value) <=
                currencies[_contractAddress].maximum,
            "Maximum limit reached"
        );
        require(
            bondValueMinted[msg.sender][_contractAddress].add(_value) >=
                currencies[_contractAddress].minimum,
            "Minimum limit not reached"
        );

        uint256 bondId = tokenIdCounter;

        tokenIdCounter = ++tokenIdCounter;
        uint256 exchangeRate = currencyValue[_contractAddress];

        uint256 usdcValue = _value.mul(exchangeRate);

        currencies[_contractAddress].totalMinted = currencies[_contractAddress]
            .totalMinted
            .add(_value);
        bondData[bondId] = Bond({
            id: bondId,
            staticInterestRate: currencies[_contractAddress].interestRate,
            accruedInterest: 0,
            lastUpdatedEpoch: getCurrentEpoch(),
            disqualifiedUntilEpoch: 0,
            disqualifiedEpochCount: 0,
            value: usdcValue,
            amountDeposited: _value,
            contractAddress: _contractAddress,
            mintedAt: block.timestamp
        });

        if (_contractAddress == address(0)) {
            require(
                msg.value == usdcValue,
                "Incorrect value sent for bond purchase"
            );

            payable(vault).transfer(msg.value);
        } else {
            IERC20(_contractAddress).safeTransferFrom(
                msg.sender,
                vault,
                _value
            );
        }

        _mint(msg.sender, bondId);
        emit BondMinted(msg.sender, bondId);
    }

    /**
        @dev Gets the value of a bond.
        * 
        @param tokenId the id of the bond
        *
        @return uint256 the value of the bond
        */
    function getBondValue(uint256 tokenId) public view returns (uint256) {
        Bond storage bond = bondData[tokenId];
        uint256 currentEpoch = getCurrentEpoch();

        ///  @dev Calculate total epochs elapsed since the bond was minted
        uint256 epochsElapsedSinceMint = currentEpoch.sub(
            bond.lastUpdatedEpoch
        );

        /// @dev Calculate the number of active epochs
        uint256 activeEpochs = epochsElapsedSinceMint.sub(
            bond.disqualifiedEpochCount
        );

        /// @dev Calculate total interest for active epochs
        uint256 totalScaledInterest = bond
            .value
            .mul(bond.staticInterestRate)
            .mul(activeEpochs)
            .div(10 ** 6); // Scaling down

        /// @dev Add the accrued interest to the bond value
        uint256 totalBondValue = bond.value.add(totalScaledInterest);

        return totalBondValue;
    }

    /**
        @dev  gets the current epoch period
        * 
        @return uint256 the current epoch period
        */
    function getCurrentEpoch() public view returns (uint256) {
        /// @dev returns 0 if the epoch has not started
        if (block.timestamp < startEpoch) {
            return 0;
        }
        if (block.timestamp >= endEpoch) {
            return endEpoch.sub(startEpoch).div(maxEpoch);
        }
        return block.timestamp.sub(startEpoch).div(maxEpoch);
    }

    /**
     * @dev Overrides the ERC721 tokenURI function to return a constant URL for all tokens.
     * @param tokenId The ID of the token.
     * @return string The metadata URI for all tokens.
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return METADATA_URL;
    }
}
