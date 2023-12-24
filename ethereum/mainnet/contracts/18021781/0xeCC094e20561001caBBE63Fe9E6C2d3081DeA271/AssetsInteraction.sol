// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;

import "./IMasterContract.sol";
import "./ITraits.sol";
import "./BAPApesInterface.sol";
import "./BAPTeenBullsInterface.sol";
import "./IERC721Receiver.sol";
import "./Ownable.sol";
import "./Strings.sol";

/// @title Bulls and Apes Project - Assets Interactions
/// @author BAP Dev Team
/// @notice Handle the use of the Assets inside BAP ecosystem
contract AssetsInteraction is Ownable, IERC721Receiver {
    using Strings for uint256;
    /// @notice Master contract instance
    IMasterContract public masterContract;
    /// @notice OG Bulls contract instance
    BAPApesInterface public bapApes;
    /// @notice Teen Bulls contract instance
    BAPTeenBullsInterface public bapTeenBulls;

    /// @notice Address of the wallet that signs messages
    address public secret;

    /// @notice Last token received, Used for resurrecting
    uint256 private lastTokenReceived;

    /// @notice Boolean to prevent Teens being sent to the contract, only allowed when reviving
    bool private isReviving = false;

    /// @notice Mapping to check if a Teen has been resurrected
    mapping(uint256 => bool) public isResurrected;
    /// @notice Mapping for contracts allowed to use this contract
    mapping(address => bool) public isAuthorized;

    /// @notice Resurrection event
    event TeenResurrected(
        address user,
        uint256 sacrificed,
        uint256 resurrected,
        uint256 newlyMinted,
        uint256 offChainUtility
    );

    /// @notice Event for Utility burned off chain
    event UtilityBurnedOffChain(
        address user,
        uint256 utilityId,
        uint256 timestamp
    );

    /// @notice Event emited when assets are burned for GAC / type 1 = Teens, type 2 = Apes
    event AssetsBurned(address user, uint256[] tokenIds, uint256 typeOfAsset, uint256 timestamp);

    /// @notice Deploys the contract and sets the instances addresses
    /// @param masterContractAddress: Address of the Master Contract
    /// @param apesAddress: Address of the OG Bulls contract
    /// @param teensAddress: Address of the Teen Bulls contract
    constructor(
        address masterContractAddress,
        address apesAddress,
        address teensAddress
    ) {
        masterContract = IMasterContract(masterContractAddress);
        bapApes = BAPApesInterface(apesAddress);
        bapTeenBulls = BAPTeenBullsInterface(teensAddress);
    }

    modifier onlyAuthorized() {
        require(isAuthorized[msg.sender], "Not Authorized");
        _;
    }

    /// @notice function used to burn teens for GAC
    /// @param tokenIds: IDs of the teens to burn
    /// @dev Only the owner of the assets can burn them and first needs to approve this contract
    function burnTeens(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _burnTeen(tokenIds[i]);
        }

        emit AssetsBurned(msg.sender, tokenIds, 1, block.timestamp);
    }

    // @notice function used to burn apes for GAC
    /// @param tokenIds: IDs of the apes to burn
    /// @dev Only the owner of the assets can burn them and first needs to approve this contract
    function burnApes(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            // transfer to dead address to burn
            bapApes.transferFrom(msg.sender, address(this), tokenIds[i]);
        }

        emit AssetsBurned(msg.sender, tokenIds, 2, block.timestamp);
    }

    function resurrectApe(uint256 tokenId, address recipient) external onlyAuthorized {
        require(recipient != address(0), "resurrectApe: Invalid recipient");
        require(bapApes.ownerOf(tokenId) == address(this), "resurrectApe: Invalid owner");        

        bapApes.transferFrom(address(this), recipient, tokenId);
    }

    /// @notice Handle the resurrection of a Teen Bull
    /// @param utilityId: ID of the utility used to resurrect
    /// @param sacrificed: ID of the Teen Bull sacrificed
    /// @param resurrected: ID of the Teen Bull to resurrect
    /// @param timeOut: Time out for the signature
    /// @param offChainUtility: Boolean to check if the utility is on-chain or off-chain
    /// @param signature: Signature to check above parameters
    function teenResurrect(
        uint256 utilityId,
        uint256 sacrificed,
        uint256 resurrected,
        uint256 timeOut,
        uint256 offChainUtility,
        bytes memory signature
    ) external {
        require(
            utilityId >= 30 && utilityId < 34,
            "teenResurrect: Wrong utilityId id"
        );
        require(
            timeOut > block.timestamp,
            "teenResurrect: Signature is expired"
        );
        require(
            _verifyHashSignature(
                keccak256(
                    abi.encode(
                        msg.sender,
                        utilityId,
                        sacrificed,
                        resurrected,
                        timeOut,
                        offChainUtility // 0 for on-chain, 1 for off-chain
                    )
                ),
                signature
            ),
            "teenResurrect: Signature is invalid"
        );
        require(
            !isResurrected[sacrificed],
            "teenResurrect: Can't sacrifice a resurrected Teen Bull"
        );
        require(
            !isResurrected[resurrected],
            "teenResurrect: Can't resurrect an already resurrected Teen Bull"
        );
        if (offChainUtility == 0) {
            masterContract.burn(utilityId, 1);
        } else {
            emit UtilityBurnedOffChain(msg.sender, utilityId, block.timestamp);
        }

        _burnTeen(sacrificed);

        isReviving = true;

        bapTeenBulls.airdrop(address(this), 1);

        isReviving = false;

        isResurrected[lastTokenReceived] = true;
        isResurrected[resurrected] = true;

        bapTeenBulls.safeTransferFrom(
            address(this),
            msg.sender,
            lastTokenReceived
        );

        emit TeenResurrected(
            msg.sender,
            sacrificed,
            resurrected,
            lastTokenReceived,
            offChainUtility
        );

        lastTokenReceived = 0;
    }

    /// @notice Handle the generation of Teen Bulls
    /// @dev Needs to pay METH and burn an Incubator
    function generateTeenBull() external {
        masterContract.pay(600, 300);
        masterContract.burn(1, 1);
        bapTeenBulls.airdrop(msg.sender, 1);
    }

    /// @notice Internal function to burn a Teen Bull
    /// @param tokenId: ID of the Teen Bull to burn
    /// @dev Only the owner of the Teen Bull can burn it and resurrected Teen Bulls cannot be burned
    function _burnTeen(uint256 tokenId) internal {
        require(
            bapTeenBulls.ownerOf(tokenId) == msg.sender,
            "Only the owner can burn"
        );
        require(!isResurrected[tokenId], "Can't burn resurrected teens");

        bapTeenBulls.burnTeenBull(tokenId);
    }

    /// @notice authorise a new address to use this contract
    /// @param operator Address to be set
    /// @param status Can use this contract or not
    /// @dev Only contract owner can call this function
    function setAuthorized(address operator, bool status) external onlyOwner {
        isAuthorized[operator] = status;
    }

    /// @notice Internal function to set isResurrected status on previously resurrected Teen Bulls
    /// @param tokenIds: Array of Teen Bull IDs to set isResurrected status
    /// @param boolean: Boolean to set isResurrected status
    /// @dev Only used to set isResurrected status on Teen Bulls resurrected before the contract deployment
    function setIsResurrected(
        uint256[] memory tokenIds,
        bool boolean
    ) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            isResurrected[tokenIds[i]] = boolean;
        }
    }

    /// @notice Internal function to set a new signer
    /// @param newSigner: Address of the new signer
    /// @dev Only the owner can set a new signer
    function setSigner(address newSigner) external onlyOwner {
        require(newSigner != address(0), "Invalid address");
        secret = newSigner;
    }

    /// @notice Internal function to handle the transfer of a Teen Bull during the resurrection process
    /// @param tokenId: ID of the Teen Bull to transfer
    /// @dev Only accept transfers from BAP Teens and only while reviving
    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes memory
    ) external virtual override returns (bytes4) {
        require(
            msg.sender == address(bapTeenBulls),
            "Only receive from BAP Teens"
        );
        require(isReviving, "Only accept transfers while reviving");
        lastTokenReceived = tokenId;
        return this.onERC721Received.selector;
    }

    /// @notice Transfer ownership from external contracts owned by this contract
    /// @param _contract Address of the external contract
    /// @param _newOwner New owner
    /// @dev Only contract owner can call this function
    function transferOwnershipExternalContract(
        address _contract,
        address _newOwner
    ) external onlyOwner {
        Ownable(_contract).transferOwnership(_newOwner);
    }

    /// @notice Set new contracts addresses
    /// @param  masterContractAddress, Address of the new master contract
    /// @param  apesAddress, Address of the new BAP OG contract
    /// @param  teensAddress, Address of the new BAP Teens contract
    /// @dev Only contract owner can call this function
    function setContractsAddresses(
        address masterContractAddress,
        address apesAddress,
        address teensAddress
    ) external onlyOwner {
        masterContract = IMasterContract(masterContractAddress);
        bapApes = BAPApesInterface(apesAddress);
        bapTeenBulls = BAPTeenBullsInterface(teensAddress);
    }

    /// @notice Internal function to check if a signature is valid
    /// @param freshHash: Hash to check
    /// @param signature: Signature to check
    function _verifyHashSignature(
        bytes32 freshHash,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return false;
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        address signer = address(0);
        if (v == 27 || v == 28) {
            // solium-disable-next-line arg-overflow
            signer = ecrecover(hash, v, r, s);
        }
        return secret == signer;
    }
}
