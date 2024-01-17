// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./AggregatorV3Interface.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeERC20.sol";

interface INFT {
    function mint(
        address,
        uint256,
        uint256,
        bytes memory
    ) external;
}

interface myIERC20 is IERC20 {
    function decimals() external view returns (uint8);
}

contract T2SNFTShopSO is Pausable, Ownable {
    using SafeERC20 for myIERC20;

    INFT public nft;
    address public fundsRecipient;
    mapping(uint256 => uint256) public USDPrice;
    mapping(myIERC20 => bool) public allowedStable;

    constructor(
        INFT _nftAddress,
        myIERC20[] memory _stablecoinsAddress,
        address _fundsRecipient
    ) {
        nft = _nftAddress;
        for (uint256 i; i < _stablecoinsAddress.length; i++) {
            allowedStable[_stablecoinsAddress[i]] = true;
        }
        fundsRecipient = _fundsRecipient;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function addStable(myIERC20 _address) public onlyOwner {
        require(!allowedStable[_address], "already allowed");
        allowedStable[_address] = true;
    }

    function removeStable(myIERC20 _address) public onlyOwner {
        require(allowedStable[_address], "already removed");
        allowedStable[_address] = false;
    }

    /**
     * @dev Buy NFT with the specified token.
     * will revert if allowance is not set.
     * Please check for token alowance before calling this function.
     * You may need to call the "approve" function before.
     * @param _tokenId Id of the token to be minted
     */
    function buyInUSD(
        uint256 _tokenId,
        address _to,
        uint256 _amount,
        myIERC20 _stableAddress
    ) public whenNotPaused {
        require(allowedStable[_stableAddress], "token not allowed");
        _stableAddress.safeTransferFrom(
            msg.sender,
            fundsRecipient,
            _amount * USDPrice[_tokenId] * 10**_stableAddress.decimals()
        );
        _mint(_to, _tokenId, _amount, "");
    }

    /**
     * @dev Mint a specific amount of a given token
     * @param _to Address that will receive the token
     * @param _tokenId Id of the token to mint
     * @param _amount Amount to mint
     */
    function _mint(
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    ) internal {
        nft.mint(_to, _tokenId, _amount, _data);
    }

    /**
     * @dev Set the price in USD (no decimals) of a given token
     * @param _tokenId Id of the token to change the price of
     * @param _price New price in USD (no decimals) for the token
     */
    function setPrice(uint256 _tokenId, uint256 _price) external onlyOwner {
        USDPrice[_tokenId] = _price;
    }
}
