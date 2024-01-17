// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./MetakitERC721.sol";
import "./MetakitERC20.sol";
import "./MetakitVerifier.sol";

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract MetakitAdminProxy is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    event NFTImported(
        address nftAddress,
        uint256 tokenId,
        string playerId,
        address playerAddress,
        string externalItemId,
        string sessionID
    );
    event NFTExported(
        address nftAddress,
        uint256 tokenId,
        string playerId,
        address playerAddress,
        string externalItemId,
        string sessionID
    );

    event TokenImported(
        address tokenAddress,
        uint256 amount,
        string playerId,
        address playerAddress,
        string sessionID
    );
    event TokenExported(
        address tokenAddress,
        uint256 amount,
        string playerId,
        address playerAddress,
        string sessionID
    );

    event TokenError(
        address tokenAddress,
        uint256 amount,
        string playerId,
        address playerAddress,
        string sessionID,
        string reason
    );
    event NFTError(
        address nftAddress,
        string playerId,
        address playerAddress,
        string externalItemId,
        string sessionID,
        string reason
    );

    address _verifierAddress;

    function initialize(address verifierAddress) external initializer {
        __Ownable_init();
        _verifierAddress = verifierAddress;
    }

    function changeVerifier(address newVerifier) public onlyOwner {
        _verifierAddress = newVerifier;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    //
    // TO DO CREATE GENERIC VALIDATOR USING ARRAYS
    //
    // function _checkMetaKitSigningService(
    //     address[] calldata _address,
    //     uint256[] calldata _integers,
    //     string[] calldata _string,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // ) external {
    //     // Verifier verifier = Verifier(_verifierAddress);
    //     // bytes32 msgHash = keccak256(
    //     //     abi.encodePacked(nftAddress, playerID, sessionID, 'IMPORT')
    //     // );
    //     // msgHash = keccak256(
    //     //     abi.encodePacked('\x19Ethereum Signed Message:\n32', msgHash)
    //     // );
    //     // require(
    //     //     verifier.isSigned(_owner, msgHash, v, r, s),
    //     //     'Metakit::  Invalid signature'
    //     // );
    // }

    function validateMessage(
        address _ownerAddress,
        bytes32 msgHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public returns (bool) {
        // Validate
        Verifier verifier = Verifier(_verifierAddress);

        msgHash = keccak256(
            abi.encodePacked('\x19Ethereum Signed Message:\n32', msgHash)
        );
        require(
            verifier.isSigned(_ownerAddress, msgHash, v, r, s),
            'Metakit:: Invalid signature'
        );
        // Validate

        return true;
    }

    function validateBlockNumber(uint256 maxBlockNumber) internal view {
        require(
            block.number < maxBlockNumber,
            'Metakit:: Invalid block number'
        );
    }

    function importNFT(
        address nftAddress,
        uint256 tokenId,
        string memory playerId,
        string memory externalItemId,
        string memory sessionId,
        // maxBlockNumber
        uint256 maxBlockNumber,
        // sig
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool sucess, string memory errorMsg) {
        // check current blocknumber + timestamp
        MetakitAdminProxy.validateBlockNumber(maxBlockNumber);
        //
        MetaERC721 meta = MetaERC721(nftAddress);
        // blockscope validation
        {
            // get contract owner
            address _ownerAddress = meta.owner();

            // build params
            bytes32 msgHash = keccak256(
                abi.encodePacked(
                    nftAddress,
                    '/',
                    playerId,
                    '/',
                    sessionId,
                    '/',
                    'IMPORT',
                    '/',
                    maxBlockNumber
                )
            );

            // Validate
            MetakitAdminProxy.validateMessage(_ownerAddress, msgHash, v, r, s);
            // Validate
        }
        // target -> playerAddress, from, to, id
        try meta.importItem(msg.sender, address(this), tokenId) returns (bool) {
            emit NFTImported(
                nftAddress,
                tokenId,
                playerId,
                msg.sender, // playerAddress
                externalItemId,
                sessionId
            );
            return (true, '');
        } catch (bytes memory reason) {
            emit NFTError(
                nftAddress,
                playerId,
                msg.sender, // playerAddress
                externalItemId,
                sessionId,
                string(reason)
            );
            return (false, string(reason));
        }
    }

    function importTokens(
        address tokenAddress,
        uint256 amount,
        string memory playerId,
        string memory sessionId,
        // maxBlockNumber
        uint256 maxBlockNumber,
        // sig
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool sucess, string memory errorMsg) {
        // check current blocknumber + timestamp
        MetakitAdminProxy.validateBlockNumber(maxBlockNumber);
        //
        address playerAddress = msg.sender;
        MetakitERC20 meta = MetakitERC20(tokenAddress);

        // blockscope validation
        {
            // get contract owner
            address _ownerAddress = meta.owner();

            // build params
            bytes32 msgHash = keccak256(
                abi.encodePacked(
                    tokenAddress,
                    '/',
                    playerId,
                    '/',
                    sessionId,
                    '/',
                    'IMPORT',
                    '/',
                    maxBlockNumber
                )
            );

            // Validate
            MetakitAdminProxy.validateMessage(_ownerAddress, msgHash, v, r, s);
        }

        try meta.importTokens(playerAddress, amount) returns (bool) {
            emit TokenImported(
                tokenAddress,
                amount,
                playerId,
                playerAddress,
                sessionId
            );
            return (true, '');
        } catch (bytes memory reason) {
            emit TokenError(
                tokenAddress,
                amount,
                playerId,
                playerAddress,
                sessionId,
                string(reason)
            );
            return (false, string(reason));
        }
    }

    function exportNFT(
        address nftAddress,
        string memory playerId,
        string memory tokenURI,
        int256 tokenId,
        string memory externalItemId,
        string memory sessionId,
        // maxBlockNumber
        uint256 maxBlockNumber,
        // sig
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool sucess, string memory errorMsg) {
        // check current blocknumber + timestamp
        MetakitAdminProxy.validateBlockNumber(maxBlockNumber);
        //
        MetaERC721 meta = MetaERC721(nftAddress);
        // blockscope validation
        {
            // get contract owner
            address _ownerAddress = meta.owner();

            // build params
            bytes32 msgHash = keccak256(
                abi.encodePacked(
                    nftAddress,
                    '/',
                    tokenId,
                    '/',
                    playerId,
                    '/',
                    sessionId,
                    '/',
                    'EXPORT',
                    '/',
                    maxBlockNumber
                )
            );

            // Validate
            MetakitAdminProxy.validateMessage(_ownerAddress, msgHash, v, r, s);
        }

        try meta.exportItem(msg.sender, tokenURI, tokenId) returns (
            uint256 newtokenId
        ) {
            emit NFTExported(
                nftAddress,
                newtokenId,
                playerId,
                msg.sender,
                externalItemId,
                sessionId
            );
            return (true, '');
        } catch (bytes memory reason) {
            emit NFTError(
                nftAddress,
                playerId,
                msg.sender,
                externalItemId,
                sessionId,
                string(reason)
            );
            return (false, string(reason));
        }
    }

    function exportTokens(
        address tokenAddress,
        uint256 amount,
        string memory playerId,
        string memory sessionId,
        // maxBlockNumber
        uint256 maxBlockNumber,
        // sig
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool sucess, string memory errorMsg) {
        // check current blocknumber + timestamp
        MetakitAdminProxy.validateBlockNumber(maxBlockNumber);
        //
        address playerAddress = msg.sender;
        MetakitERC20 meta = MetakitERC20(tokenAddress);
        // blockscope validation
        {
            // get contract owner
            address _ownerAddress = meta.owner();

            // build params
            bytes32 msgHash = keccak256(
                abi.encodePacked(
                    tokenAddress,
                    '/',
                    playerId,
                    '/',
                    amount,
                    '/',
                    sessionId,
                    '/',
                    'EXPORT',
                    '/',
                    maxBlockNumber
                )
            );

            // Validate
            MetakitAdminProxy.validateMessage(_ownerAddress, msgHash, v, r, s);
        }

        try meta.exportTokens(playerAddress, amount) returns (bool) {
            emit TokenExported(
                tokenAddress,
                amount,
                playerId,
                playerAddress,
                sessionId
            );
            return (true, '');
        } catch (bytes memory reason) {
            emit TokenError(
                tokenAddress,
                amount,
                playerId,
                playerAddress,
                sessionId,
                string(reason)
            );
            return (false, string(reason));
        }
    }
}
