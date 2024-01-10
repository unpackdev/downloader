// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC721Receiver.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";

contract Bricktoforge is Ownable {
    bool public isActive = false;
    address bricktopiansAddress;

    uint256[] private tokens;

    mapping(uint256 => uint256) public tokenPairs;

    event forgeEvent(address _from, uint256 _burnTokenId, uint _upgradeTokenId);

    constructor(address _bricktopiansAddress) {
        bricktopiansAddress = _bricktopiansAddress;
    }

    function forge(uint256 _burnTokenId, uint256 _upgradeTokenId)
        external
        
    {
        require(isActive, "The forge is not active");
        require(_burnTokenId != _upgradeTokenId, "Cannot forge the same token");
        require(
            ERC721(bricktopiansAddress).ownerOf(_upgradeTokenId) == msg.sender,
            "Sender must be the owner of the upgrade token"
        );

        transfer(_burnTokenId, msg.sender, address(this));

        tokenPairs[_burnTokenId] = _upgradeTokenId;

        emit forgeEvent(msg.sender, _burnTokenId, _upgradeTokenId);
    }

    function transfer(
        uint256 _tokenId,
        address _from,
        address _to
    ) public {
        ERC721(bricktopiansAddress).safeTransferFrom(_from, _to, _tokenId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function burn(uint256 _tokenId) public onlyOwner {
        ERC721Burnable(bricktopiansAddress).burn(_tokenId);
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = ERC721(bricktopiansAddress).balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = ERC721Enumerable(bricktopiansAddress)
                    .tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function burnAllTokens() public onlyOwner {
        tokens = this.tokensOfOwner(address(this));

        for (uint256 i = 0; i < tokens.length; i++) {
            ERC721Burnable(bricktopiansAddress).burn(tokens[i]);
        }
    }

    function toggleIsActive() external onlyOwner {
        isActive = !isActive;
    }
}
