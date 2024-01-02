//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721.sol";
import "./Counters.sol";
import "./Math.sol";
import "./Strings.sol";
import "./AdminOwnable.sol";

contract DougSoul is ERC721, AdminOwnable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    mapping(address => uint16) private _whitelist;
    mapping(address => bool) private _allowedShareCodes;
    mapping(uint256 => bool) private _redeemed;
    uint256 _epochMax1;
    uint256 _epochMax2;
    uint256 _epochMax3;
    uint256 _price;
    uint256 _finalTokenId;
    string _imagesRootHash;
    address _redeemer;
    uint256 _dougTokenOffset;

    constructor(
        uint256 price, 
        uint256 epochMax1,
        uint256 epochMax2, 
        uint256 epochMax3,
        string memory imagesRootHash,
        uint256 finalTokenId,
        uint256 dougTokenOffset) ERC721("Doug SBT", "NFT") AdminOwnable(msg.sender)
    {
        _price = price;
        _epochMax1 = epochMax1;
        _epochMax2 = epochMax2;
        _epochMax3 = epochMax3;
        _imagesRootHash = imagesRootHash;
        _finalTokenId = finalTokenId;
        _dougTokenOffset = dougTokenOffset;
    }

    /// PUBLIC ================================
    function getOffset() public view returns(uint256) {
        return _dougTokenOffset;
    }

    function getEpoch(uint256 token) public view returns(uint8) {
        if(token <= _epochMax1) 
            return 1;
        if(token <= _epochMax2) 
            return 2;
        if(token <= _epochMax3) 
            return 3;

        return 4;
    }
    
    function getCurrentPrice() public view returns(uint256) {
        return _price;
    }

    function getWhiteListCount() public view returns (uint16) {
        return _whitelist[_msgSender()];
    }

    function getWhiteListCountForAddress(address wallet) public view returns (uint16) {
        return _whitelist[wallet];
    }
    
    function getLastTokenId() public view returns (uint256) {
        return _tokenIds.current() + _dougTokenOffset;
    }

    function mint() public payable returns (uint256) {
        require(msg.value >= _price, "incorrect price");
        require(_whitelist[_msgSender()] >= 1, "not on whitelist");
        require(_tokenIds.current() + _dougTokenOffset < _finalTokenId, "all SBTs minted");

        _whitelist[_msgSender()] = _whitelist[_msgSender()] - 1;
        _allowedShareCodes[_msgSender()] = true;

        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current() + _dougTokenOffset;

        _safeMint(_msgSender(), newItemId);

        return newItemId;
    }

    function burn(uint256 tokenId) public {
        require(_msgSender() == ownerOf(tokenId), "not owner");
        require(_exists(tokenId), "does not exist");
        _burn(tokenId);
    }

    function tokenName(uint8 epoch) internal pure returns (string memory) {
        if(epoch == 2) {
            return "Epoch #2 Soulbound Token";
        }
        else if(epoch == 3) {
            return "Epoch #3 Soulbound Token";
        }

        return "";
    }

    function tokenDescription(uint8 epoch) internal pure returns (string memory) {
        if(epoch == 2) {
            return 'Redeem this token for one \u201cBonus Footage\u201d pre-reveal box at [https://app.commanderdoug.io/redeem](https://app.commanderdoug.io/redeem). \u201cBonus Footage\u201d Doug Boxes contain one Doug and the holder will be airdropped two additional Doug boxes prior to unboxing day.';
        }
        else if(epoch == 3) {
            return 'Redeem this token for one \u201cDirector\u2019s Cut\u201d pre-reveal box at [https://app.commanderdoug.io/redeem](https://app.commanderdoug.io/redeem). \u201cDirector\u2019s Cut\u201d Doug Boxes contain one Doug and the holder will be airdropped one additional Doug box prior to unboxing day.';
        }

        return "Redeem this token for one regular pre-reveal box (contains one Doug) at [https://app.commanderdoug.io/redeem](https://app.commanderdoug.io/redeem).";
    }

    function tokenImage(uint256 tokenId, uint8 epoch) internal view returns (string memory) {
        if(_redeemed[tokenId]) {
            if(epoch == 2) {
                return string(abi.encodePacked("ipfs://", _imagesRootHash, "/EP2_redeemed.png"));
            }
            else if(epoch == 3) {
                return string(abi.encodePacked("ipfs://", _imagesRootHash, "/EP3_redeemed.png"));
            }
            else {
                return string(abi.encodePacked("ipfs://", _imagesRootHash, "/WL_redeemed.png"));
            }
        }
        else {

            if(epoch == 2) {
                return string(abi.encodePacked("ipfs://", _imagesRootHash, "/EP2.png"));
            }
            else if(epoch == 3) {
                return string(abi.encodePacked("ipfs://", _imagesRootHash, "/EP3.png"));
            }
            else {
                return string(abi.encodePacked("ipfs://", _imagesRootHash, "/WL.png"));
            }
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) { 
        uint8 epoch = getEpoch(tokenId);
        string memory name = tokenName(epoch);
        string memory desc = tokenDescription(epoch);
        string memory image = tokenImage(tokenId, epoch);
        string memory redeemed = _redeemed[tokenId] ? "Yes" : "No";
        string memory epochValue = epoch == 2 ? "Epoch 2" : (epoch == 3 ? "Epoch 3" : "Early Access");

        return string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        //bytes(
                            abi.encodePacked( 
                                '{\n',
                                '"name": "', name, '",\n',
                                '"description": "', desc, '",\n',
                                '"image": "', image, '",\n',
                                '"external_url":"https://www.commanderdoug.io",\n',
                                '"attributes": [{ "trait_type": "Redeemed", "value": "', redeemed, '"}, { "trait_type": "Minting Phase", "value": "', epochValue, '"}]\n',
                                '}'
                                )
                        //)
                    )
                )
        );
    }

    function redeem(uint256 tokenId) public {
        require(msg.sender == _redeemer, "Must be redeemer contract");
        _redeemed[tokenId] = true;
    }

    function isRedeemed(uint256 tokenId) public view returns(bool) {
        return _redeemed[tokenId];
    }

    function getIsAllowedSharedCodes() public view returns (bool) {
        return _allowedShareCodes[_msgSender()];
    }

    function getIsAllowedSharedCodes(address wallet) public view returns (bool) {
        return _allowedShareCodes[wallet];
    }

    /// Owner ================================
    function setAdmin(address admin) public isOwner {
        _admin = admin;
    }

    function setRedeemer(address redeemer) public isOwner {
        _redeemer = redeemer;
    }

    function setEpochMax2(uint256 epochMax2) public isOwner {
        _epochMax2 = epochMax2;
    }

    function setEpochMax3(uint256 epochMax3) public isOwner {
        _epochMax3 = epochMax3;
    }

    function setImagesRootHash(string memory imagesRootHash) public isOwner {
        _imagesRootHash = imagesRootHash;
    }

    function setFinalTokenId(uint256 finalTokenId) public isOwner {
        _finalTokenId = finalTokenId;
    }

    function setDougOffset(uint256 dougTokenOffset) public isOwner {
        _dougTokenOffset = dougTokenOffset;
    }

    function setPrice(uint256 price) public isOwner { 
        _price = price;
    }

    /// Admin ================================
    function whitelistAddress(address wallet, uint16 count, bool allowedShareCodes) public isAdminOrOwner {
        _whitelist[wallet] = count;
        _allowedShareCodes[wallet] = allowedShareCodes;
    }

    function whitelistAddresses(address [] memory wallets, uint16 whitelistCount, bool allowedShareCodes) public isAdminOrOwner {
        for(uint i = 0; i < wallets.length; i++) {
            address wallet = wallets[i];
            _whitelist[wallet] = whitelistCount;
            _allowedShareCodes[wallet] = allowedShareCodes;
        }
    }

    function withdrawAll(address to) public isOwner {
        address payable _to = payable(to);
        uint256 _balance = address(this).balance;
        _to.transfer(_balance);
    }
    

    /// Internal ================================
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        require(from == address(0) || to == address(0), "Soulbound token is non-transferrable");
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }
}


/// @title Base64
/// @author Brecht Devos - <brecht@loopring.org>
/// @notice Provides a function for encoding some bytes in base64
/// @notice NOT BUILT BY ETHERORCS TEAM. Thanks Bretch Devos!
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}