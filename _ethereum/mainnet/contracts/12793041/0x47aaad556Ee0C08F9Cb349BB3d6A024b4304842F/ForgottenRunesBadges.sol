// Forgotten Runes Badges
//
// https://www.forgottenrunes.com
// Twitter: https://twitter.com/forgottenrunes
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract ForgottenRunesBadges is ERC721Burnable, Ownable {
    using SafeMath for uint256;

    uint256 public _nextBadgeTypeIdx = 0;
    mapping(uint256 => string) private _badgeURIs;

    constructor() ERC721('ForgottenRunesBadges', 'WIZARDBADGES') {}

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function badgeURI(uint256 badgeId) public view returns (string memory) {
        require(
            badgeId < _nextBadgeTypeIdx,
            'ForgottenRunesBadge: URI query for nonexistent badge type'
        );
        return _badgeURIs[badgeId];
    }

    /*
     * Only the owner can do these things
     */

    function issue(string memory _newURI) public onlyOwner {
        _badgeURIs[_nextBadgeTypeIdx] = _newURI;
        _nextBadgeTypeIdx += 1;
    }

    function _safeMintBadge(
        uint256 _badgeId,
        address _to,
        uint256 _tokenId
    ) internal virtual {
        require(
            _badgeId < _nextBadgeTypeIdx,
            'ForgottenRunesBadge: nonexistent badge type'
        );
        _safeMint(_to, _tokenId);
        _setTokenURI(_tokenId, _badgeURIs[_badgeId]);
    }

    function mint(uint256 _badgeId, uint256 _numBadges) public onlyOwner {
        uint256 currentSupply = totalSupply();
        uint256 index;
        for (index = 0; index < _numBadges; index++) {
            _safeMintBadge(_badgeId, owner(), currentSupply + index);
        }
    }

    // emergency exit functions
    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function forwardERC20s(IERC20 _token, uint256 _amount) public onlyOwner {
        _token.transfer(msg.sender, _amount);
    }
}
