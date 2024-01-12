//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Holder.sol";
import "./ERC721.sol";
import "./IERC721.sol";

contract ERC721Staked is ERC721, Ownable, ERC721Holder {
    using Strings for uint;
    IERC721 public nft;

    struct StakerWallet {
        uint[] maskTokenIds;
        mapping(uint => uint) timeStaked;
    }

    string public contractURI;
    string public baseTokenURI;
    string public baseTokenURIExpress;
    string public baseTokenURIGold;
    uint public expressPass;
    uint public goldPass;
    uint public totalStaked;
    uint public mintId;
    mapping(uint => StakerWallet) Stakers;
    mapping(uint => bool) public rareMasks;
    mapping(uint => uint) public tokenOwner;

    constructor(address _nft, string memory _name, string memory _symbol, string memory _contractURI, string memory _baseTokenURI, string memory _baseTokenURIExpress, string memory _baseTokenURIGold) ERC721(_name, _symbol) {
        nft = IERC721(_nft);
        contractURI = _contractURI;
        baseTokenURI = _baseTokenURI;
        baseTokenURIExpress = _baseTokenURIExpress;
        baseTokenURIGold = _baseTokenURIGold;
        expressPass = 5;
        goldPass = 10;
    }

    //view functions
    function getStakedTokens(uint _tokenId) public view returns (uint[] memory tokens) {
        return Stakers[_tokenId].maskTokenIds;
    }

    function getStakedTime(uint _tokenId) public view returns (uint stakeTime) {
        return Stakers[tokenOwner[_tokenId]].timeStaked[_tokenId];
    }

    function hasRare(uint _tokenId) public view returns (bool) {
        uint[] memory tokens = Stakers[_tokenId].maskTokenIds;
        for (uint i = 0; i < tokens.length; i++) {
            if (rareMasks[tokens[i]]) {
                return true;
            }
        }
        return false;
    }

    function passType(uint _tokenId) public view returns (uint) {
        uint size = Stakers[_tokenId].maskTokenIds.length;
        if (size >= goldPass || hasRare(_tokenId)) {
            return 3; //gold pass
        } else if (size >= expressPass) {
            return 2; //express pass
        } else if (size > 0) {
            return 1; // general pass
        }
        return 0; // no pass
    }

    function tokenURI(uint _tokenId) public view override returns (string memory) {
        uint pType = passType(_tokenId);

        if (pType == 3) {
            return string(abi.encodePacked(baseTokenURIGold, _tokenId.toString()));
        } else if (pType == 2) {
            return string(abi.encodePacked(baseTokenURIExpress, _tokenId.toString()));
        }
        return string(abi.encodePacked(baseTokenURI, _tokenId.toString()));
    }

    //stake
    function stake(address user, uint tokenID) public {
        _stake(user, tokenID, mintId);
        _mint(user, mintId++);
    }

    function batchStake(address user, uint[] memory tokenIDs) public {
        for (uint i = 0; i < tokenIDs.length; i++) {
            _stake(user, tokenIDs[i], mintId);
        }
        _mint(user, mintId++);
    }

    function _stake(address _user, uint _tokenId, uint _newTokenId) internal {
        //get/create Staker Wallet
        StakerWallet storage _staker = Stakers[_newTokenId];

        //transfer ownership (assumes pre-approved before this is called)
        nft.safeTransferFrom(_user, address(this), _tokenId);

        //update Owner Wallet
        _staker.maskTokenIds.push(_tokenId);
        _staker.timeStaked[_tokenId] = block.timestamp;

        //update tokenOwner mapping
        tokenOwner[_tokenId] = _newTokenId;

        //update total amount staked
        totalStaked++;
    }

    //unstake
    function unstake(address user, uint tokenId, uint maskTokenID) public {
        _unstake(user, tokenId, maskTokenID);
    }

    function batchUnstake(address user, uint tokenId, uint[] memory maskTokenIds) public {
        for (uint i = 0; i < maskTokenIds.length; i++) {
            _unstake(user, tokenId, maskTokenIds[i]);
        }
    }

    function _unstake(address _user, uint _tokenId, uint _maskTokenId) internal {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not an operator for this tokenId");
        require(tokenOwner[_maskTokenId] == _tokenId, "Pass does not contain that tokenId");
        //get Staker Wallet
        StakerWallet storage _staker = Stakers[_tokenId];

        //transfer ownership back to user
        // nft.approve(_user, _maskTokenId);
        nft.safeTransferFrom(address(this), _user, _maskTokenId);

        //clear out staked info
        delete tokenOwner[_tokenId];
        delete _staker.timeStaked[_tokenId];
        totalStaked--;

        //replace the removed token id at its current index with the last value in the array
        //and then pop() off the last index.  We do not care about the order of this
        //array
        bool done = false;
        uint i = 0;
        do {
            // for (uint i = 0; i < _staker.maskTokenIds.length - 1; i++) { //this seems to defeat purpose of while loop
            if (_staker.maskTokenIds[i] == _maskTokenId) {
                _staker.maskTokenIds[i] = _staker.maskTokenIds[_staker.maskTokenIds.length - 1];
                _staker.maskTokenIds.pop();
                done = true;
            }
            // }
            i++;
        } while (done == false);
        if (passType(_tokenId) == 0) {
            _burn(_tokenId);
        }
    }

    //uniswap multicall
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert("");
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }

    function setBaseTokenURIGeneral(string memory _baseTokenURIGeneral) external onlyOwner {
        baseTokenURI = _baseTokenURIGeneral;
    }

    function setBaseTokenURIExpress(string memory _baseTokenURIExpress) external onlyOwner {
        baseTokenURIExpress = _baseTokenURIExpress;
    }

    function setBaseTokenURIGold(string memory _baseTokenURIGold) external onlyOwner {
        baseTokenURIGold = _baseTokenURIGold;
    }

    function setExpressPass(uint _expressPass) external onlyOwner {
        expressPass = _expressPass;
    }

    function setGoldPass(uint _goldPass) external onlyOwner {
        goldPass = _goldPass;
    }

    function setRareMask(uint _tokenId) external onlyOwner {
        rareMasks[_tokenId] = true;
    }

    function setRareMasks(uint[] memory _tokenIds) external onlyOwner {
        for (uint i = 0; i < _tokenIds.length; i++) {
            rareMasks[_tokenIds[i]] = true;
        }
    }

    function revokeRareMask(uint _tokenId) external onlyOwner {
        rareMasks[_tokenId] = false;
    }

    function revokeRareMasks(uint[] memory _tokenIds) external onlyOwner {
        for (uint i = 0; i < _tokenIds.length; i++) {
            rareMasks[_tokenIds[i]] = false;
        }
    }
}
