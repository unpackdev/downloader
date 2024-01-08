// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC721.sol";
import "./ERC721Holder.sol";
import "./Ownable.sol";

import "./IERC721Draft.sol";

contract EtherTulipsBridge is ERC721Holder, Ownable {
    address public v1Address = address(0);
    address public v2Address = address(0);

    IERC721Draft private v1Contract;
    IERC721 private v2Contract;

    function v1ToV2(uint256 _tokenId) public {
        require(_initialized(), "contract addresses not set");
        require(v1Contract.ownerOf(_tokenId) == _msgSender(), "only the token owner can bridge");
        require(_tokenId <= 7250, "only tokens with id <= 7250 can be bridged");

        v1Contract.transferFrom(_msgSender(), address(this), _tokenId);
        v2Contract.safeTransferFrom(address(this), _msgSender(), _tokenId);
    }

    function v2ToV1(uint256 _tokenId) public {
        require(_initialized(), "contract addresses not set");
        require(v2Contract.ownerOf(_tokenId) == _msgSender(), "only the token owner can bridge");
        require(_tokenId <= 7250, "only tokens with id <= 7250 can be bridged");

        v2Contract.safeTransferFrom(_msgSender(), address(this), _tokenId);
        v1Contract.transfer(_msgSender(), _tokenId);
    }

    function setContracts(address _v1Address, address _v2Address) external onlyOwner {
        v1Address = _v1Address;
        v2Address = _v2Address;

        v1Contract = IERC721Draft(v1Address);
        v2Contract = IERC721(v2Address);
    }

    function _initialized() internal view returns (bool) {
        return v1Address != address(0) && v2Address != address(0);
    }
}
