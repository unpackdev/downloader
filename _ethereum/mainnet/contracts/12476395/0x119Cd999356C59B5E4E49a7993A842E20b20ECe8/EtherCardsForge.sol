//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.0 <0.8.0;

import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./IERC20.sol";

// import "./console.sol";
import "./Ownable.sol";

/**
 * @dev EtherCardsForge contract
 *
 * v1, logging
 *
 */
contract EtherCardsForge is Ownable {
    
    // Events
    event LayerTransfer(uint16 indexed src, uint16 indexed dst, bytes callData);
    event Logged(address indexed from, bytes indexed data);

    // 
    IERC721 public NFTContract;
    address public Vault;

    // list of cards protected from burning on one action
    mapping(uint16 => bool) public ForgeProtector;

    bool public _initialized = false;
    bool public _locked = false;

    constructor(address _NFTContractAddress, address _VaultAddress) {
        NFTContract = IERC721(_NFTContractAddress);
        Vault = _VaultAddress;
    }

    /**
     * Used to set the 2500 ids that have "Forge Protector" trait active
     * 0 to 10000 / uint16 - 0 to 65535
     */
    function setForgeProtection(uint16[] calldata tokenIds) external onlyOwner {
        require(!_initialized, "Must not be initialized");
        for (uint16 j = 0; j < tokenIds.length; j++) {
            ForgeProtector[tokenIds[j]] = true;
        }
    }

    /**
     * Log Data in the chain
     */
    function logData(bytes calldata _data) external {
        require(!_locked, "Must not be locked");
        emit Logged(msg.sender, _data);
    }

    /**
     * Call after Forge Protection ids have been loaded in order to seal.
     */
    function setInitialized() external onlyOwner {
        require(!_initialized, "Must not be initialized");
        _initialized = true;
    }

    function onERC721Received(
        address,    // operator
        address from,
        uint256 receivedTokenId,
        bytes memory data
    ) external returns (bytes4) {
        require(_initialized, "Must be initialized");
        require(!_locked, "Must not be locked");

        require(
            msg.sender == address(NFTContract),
            "Must be NFTContract address"
        );

        // Parse data
        uint8 version;
        uint8 callType;
        uint16 srcTokenId;
        uint16 dstTokenId;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            // add 32 since input is treated as a variable with 32 bit white space
            let ptr := add(data, 32)

            // hex 0101000b000c0100000101

            // byte 0 - version
            version := byte(0, mload(ptr))
            ptr := add(ptr, 1)

            // byte 1 - call type
            callType := byte(0, mload(ptr))
            ptr := add(ptr, 1)
        }

        // Validate forge type
        require(version == 1, "Binary data version must be 1");

        if (callType == 1) {

            // bool layer1;
            // bool layer2;
            // bool layer3;
            // bool layer4;
            // bool layer5;

            assembly {
                let ptr := add(data, 34)

                // byte [2-3] Load dstTokenId -> mul first byte by 256 and add the rest from byte 2
                dstTokenId := add(
                    mul(byte(0, mload(ptr)), 256),
                    byte(0, mload(add(ptr, 1)))
                )
                ptr := add(ptr, 2)

                // byte [4-5] Load srcTokenId -> mul first byte by 256 and add the rest from byte 2
                srcTokenId := add(
                    mul(byte(0, mload(ptr)), 256),
                    byte(0, mload(add(ptr, 1)))
                )
                ptr := add(ptr, 2)

                // // byte 6 - layer 1
                // layer1 := byte(0, mload(ptr))
                // ptr := add(ptr, 1)

                // // byte 7 - layer 2
                // layer2 := byte(0, mload(ptr))
                // ptr := add(ptr, 1)

                // // byte 8 - layer 3
                // layer3 := byte(0, mload(ptr))
                // ptr := add(ptr, 1)

                // // byte 9 - layer 4
                // layer4 := byte(0, mload(ptr))
                // ptr := add(ptr, 1)

                // // byte 10 - layer 5
                // layer5 := byte(0, mload(ptr))
            }

            // Validate that the destination token actually exists by finding out if it has the correct owner
            require(
                NFTContract.ownerOf(dstTokenId) == from,
                "Destination token must be owned by the same address as source token"
            );

            // Make sure our user did not mess with the byte data
            require(
                receivedTokenId == srcTokenId,
                "Token sent to contract must match srcTokenId"
            );

            // default receiver for cards.. Vault
            address receiver = Vault;

            // check if received card has forge protector trait
            if (ForgeProtector[srcTokenId]) {
                // yes. Burn trait and return it to sender
                ForgeProtector[srcTokenId] = false;
                receiver = from;
            }

            // transfer but don't call receiver
            // safeTransferFrom would be a bad idea here
            NFTContract.transferFrom(address(this), receiver, srcTokenId);

            emit LayerTransfer(srcTokenId, dstTokenId, data);

            return this.onERC721Received.selector;
        } 
        
        revert("Call type not implemented");
        // return this.onERC721Received.selector;
    }

    // lock mechanism
    function lock(bool mode) external onlyOwner {
        _locked = mode;
    }

    // blackhole prevention methods
    function retrieveERC20(address _tracker, uint256 amount) external onlyOwner {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }
}
