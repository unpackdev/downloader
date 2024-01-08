// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./ERC1155.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";

library UintLibrary {
    function toString(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}

library StringLibrary {
    using UintLibrary for uint256;

    function append(string memory _a, string memory _b) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory bab = new bytes(_ba.length + _bb.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }

    function append(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory bbb = new bytes(_ba.length + _bb.length + _bc.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bbb[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bbb[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) bbb[k++] = _bc[i];
        return string(bbb);
    }

    function recover(string memory message, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        bytes memory msgBytes = bytes(message);
        bytes memory fullMessage = concat(
            bytes("\x19Ethereum Signed Message:\n"),
            bytes(msgBytes.length.toString()),
            msgBytes,
            new bytes(0), new bytes(0), new bytes(0), new bytes(0)
        );
        return ecrecover(keccak256(fullMessage), v, r, s);
    }

    function concat(bytes memory _ba, bytes memory _bb, bytes memory _bc, bytes memory _bd, bytes memory _be, bytes memory _bf, bytes memory _bg) internal pure returns (bytes memory) {
        bytes memory resultBytes = new bytes(_ba.length + _bb.length + _bc.length + _bd.length + _be.length + _bf.length + _bg.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) resultBytes[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) resultBytes[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) resultBytes[k++] = _bc[i];
        for (uint i = 0; i < _bd.length; i++) resultBytes[k++] = _bd[i];
        for (uint i = 0; i < _be.length; i++) resultBytes[k++] = _be[i];
        for (uint i = 0; i < _bf.length; i++) resultBytes[k++] = _bf[i];
        for (uint i = 0; i < _bg.length; i++) resultBytes[k++] = _bg[i];
        return resultBytes;
    }
}

contract NiftysistasTraits is ERC1155, Ownable, Pausable {
    using SafeMath for uint;

    bool isSistasFinalized;
    bool isBratsFinalized;

    address sistasContract;
    address bratsContract;

    uint[] private specialTraits = [551, 565, 610, 617, 650, 706, 759, 770, 790, 818];
    uint private rn = 0;

    string public _name;
    string public _symbol;

    mapping (uint => bool) private claimedMap;
    mapping (uint256 => uint256) public tokenSupply;

    NiftydudesContract public dudesContract = NiftydudesContract(0x892555E75350E11f2058d086C72b9C94C9493d72);

    constructor (string memory name_, string memory symbol_) ERC1155("https://niftysistas.com/traits/metadata/") {
        _name = name_;
        _symbol = symbol_;
    }

    function mint(uint[] calldata traits, address to) external {
        require(sistasContract == msg.sender || bratsContract == msg.sender, "no permission");

        for (uint i=0; i < traits.length; i++) {
           tokenSupply[traits[i]] = tokenSupply[traits[i]].add(1);
           _mint(to, traits[i], 1, "");
        }
    }

    function setURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }

    function uri(uint256 _id) public view override returns (string memory) {
            require(tokenSupply[_id] > 0, "NONEXISTENT_TOKEN");
            
            return StringLibrary.append(super.uri(_id), UintLibrary.toString(_id)
        );
    }

    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }

    function setSistasContract(address _address) external onlyOwner {
        require(!isSistasFinalized, "not possible when finalized");
        sistasContract = _address;
    }

    function setBratsContract(address _address) external onlyOwner {
        require(!isBratsFinalized, "not possible when finalized");
        bratsContract = _address;
    }    

    function finalizeSistas() external onlyOwner {
        isSistasFinalized = true;
    }

    function finalizeBrats() external onlyOwner {
        isBratsFinalized = true;
    }

    function burn(address account, uint256 tokenId, uint256 amount) external {
        require(sistasContract == msg.sender || balanceOf(msg.sender, tokenId) >= amount, "Burnable: caller is not approved");
        tokenSupply[tokenId] = tokenSupply[tokenId].sub(amount);

        _burn(account, tokenId, amount);
    }    

    function claimSpecialTrait(uint[] calldata dudeIds) external {
        require(!paused(), "claiming period ended");
        require(rn!=0, "not randomized");

        for (uint i=0; i < dudeIds.length; i++) {
            require(dudesContract.ownerOf(dudeIds[i]) == msg.sender, "sender is not owner of dude");
            require(!claimedMap[dudeIds[i]], "trait for this dude has already been claimed");
            
            claimedMap[dudeIds[i]] = true;

            uint tokenID = specialTraits[(dudeIds[i]+rn)%10];
            tokenSupply[tokenID] = tokenSupply[tokenID].add(1);

            _mint(msg.sender, tokenID, 1, "");
        }
    }

    function randomizeSpecialTraits() external {
        require(rn==0, "rn already set");

        rn = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, blockhash(block.number-1))));
    }

    function getSpecialTraitIfNotClaimed(uint256[] calldata dudeIDs) external view returns (uint[] memory) {
        uint256[] memory result = new uint256[](dudeIDs.length);
        
        for (uint i=0; i < dudeIDs.length; i++) {
            if(!claimedMap[dudeIDs[i]]) {
                result[i] = specialTraits[(dudeIDs[i]+rn)%10];
            } else {
                result[i] = 999;
            }
        }
        return result;
    }

    function endClaiming() external onlyOwner {
        _pause();
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }    
}

 interface NiftydudesContract {
    function ownerOf(uint dudeId) external view returns (address);
 }