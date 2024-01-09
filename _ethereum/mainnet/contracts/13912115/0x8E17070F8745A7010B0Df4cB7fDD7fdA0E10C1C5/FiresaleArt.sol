// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./ERC20Burnable.sol";
import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./MerkleProof.sol";

import "./LITToken.sol";

contract FiresaleArt is
    Initializable,
    OwnableUpgradeable,
    IERC721Receiver,
    PausableUpgradeable
{
    // address where NFTs and $LIT are sent
    address private _treasury;

    LITToken public token;

    // used in depositMultiERC721Batch
    // represents multiple NFTs across multiple ERC721 contracts
    struct Bundle {
        address from; // address of the ERC721 contract
        uint256[] tokenIds; // array of tokenIds
        bytes32[] proof;
    }

    bytes32 public NFTwhitelist;

    bool public whitelistActive;

    event whitelistUpdated(address updater);

    /**
     * @dev called by the owner to turn on the nft collection whitelisting
     */
    function toggleWhitelist() public virtual onlyOwner {
        whitelistActive = !whitelistActive;
        emit whitelistUpdated(msg.sender);
    }

    /**
     * @dev called by the owner to set merkle tree root for the nft collection whitelist
     */
    function setWhitelist(bytes32 _whitelist) public virtual onlyOwner {
        NFTwhitelist = _whitelist;
    }

    function initialize(LITToken _token) public virtual initializer {
        __Pausable_init();
        __Ownable_init();
        token = _token;
        whitelistActive = false;
    }

    /**
     * @dev called by the owner to pause the contract
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev called by the owner to pause the contract
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev called by the owner to determine where nfts are eventually transferred
     */
    function setTreasury(address treasury) public virtual onlyOwner {
        _treasury = treasury;
    }

    function getTreasury() external view returns (address) {
        return _treasury;
    }

    /**
     * @dev called when the contract receives an ERC721 token, will revert if project is not whitelisted
     * in exchange for nfts, depositers will receive $LIT
     */
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata _data
    ) public virtual override whenNotPaused returns (bytes4) {
        require(_treasury != address(0), "Treasury cannot be the 0x0 address");
        bytes32[] memory bytesArray = bytesToBytes32Array(_data);
        if (whitelistActive) {
            require(
                _verify(_leaf(msg.sender), bytesArray),
                "Not a whitelisted contract"
            );
        }

        IERC721(msg.sender).safeTransferFrom(address(this), _treasury, tokenId);
        token.mint(address(this), 1, from);

        return this.onERC721Received.selector;
    }

    /**
     * @dev converts bytes to bytes32[]
     */
    function bytesToBytes32Array(bytes memory data)
        public
        pure
        returns (bytes32[] memory)
    {
        // Find 32 bytes segments nb
        uint256 dataNb = data.length / 32;
        // Create an array of dataNb elements
        bytes32[] memory dataList = new bytes32[](dataNb);
        // Start array index at 0
        uint256 index = 0;
        // Loop all 32 bytes segments
        for (uint256 i = 32; i <= data.length; i = i + 32) {
            bytes32 temp;
            // Get 32 bytes from data
            assembly {
                temp := mload(add(data, i))
            }
            // Add extracted 32 bytes to list
            dataList[index] = temp;
            index++;
        }
        // Return data list
        return (dataList);
    }

    /**
     * @dev hash function for an address, used to validate inclusion in nft project whitelist
     */
    function _leaf(address contractAddress) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(contractAddress));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, NFTwhitelist, leaf);
    }

    /**
     * @dev called by nft holders to batch deposit nfts from different projects
     * this function requires that FireSale be approved to transfer the bundles of NFTs
     * in exchange for nfts, depositers will receive $LIT
     */
    function depositMultiERC721Batch(Bundle[] calldata _bundles)
        external
        virtual
        whenNotPaused
        returns (bytes4)
    {
        require(_treasury != address(0), "Treasury cannot be the 0x0 address");

        uint128 numDeposits = 0;
        for (uint256 i = 0; i < _bundles.length; i++) {
            if (whitelistActive) {
                require(
                    _verify(_leaf(_bundles[i].from), _bundles[i].proof),
                    "Not a whitelisted contract"
                );
            }
            for (uint256 j = 0; j < _bundles[i].tokenIds.length; j++) {
                IERC721(_bundles[i].from).safeTransferFrom(
                    msg.sender,
                    _treasury,
                    _bundles[i].tokenIds[j]
                );
                numDeposits++;
            }
        }

        token.mint(address(this), numDeposits, msg.sender);

        return this.depositMultiERC721Batch.selector;
    }

    receive() external payable {}
}
