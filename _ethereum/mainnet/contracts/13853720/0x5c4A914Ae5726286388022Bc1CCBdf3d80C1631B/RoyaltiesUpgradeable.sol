// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./ERC165Upgradeable.sol";
import "./IERC2981.sol";
import "./PartLib.sol";
import "./RoyaltiesLib.sol";

contract RoyaltiesUpgradeable is ERC165Upgradeable, IERC2981 {
    mapping (uint256 => PartLib.PartData[]) internal royalties;

    event RoyaltiesSet(uint256 tokenId, PartLib.PartData[] royalties);

    function __RoyaltiesUpgradeable_init_unchained() internal initializer {
        _registerInterface(RoyaltiesLib._INTERFACE_ID_ERC2981);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) override external view returns (address receiver, uint256 royaltyAmount) {
        PartLib.PartData[] memory _royalties = royalties[_tokenId];
        if(_royalties.length > 0) {
            return (_royalties[0].account, (_salePrice * _royalties[0].value)/10000);
        }
        return (address(0), 0);
    }

    function getRoyalties(uint256 id) external view returns (PartLib.PartData[] memory) {
        return royalties[id];
    }

    function calculateRoyalties(address payable to, uint96 amount) external view returns (PartLib.PartData[] memory) {
        return RoyaltiesLib.calculateRoyalties(to, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == RoyaltiesLib._INTERFACE_ID_ERC2981
        || super.supportsInterface(interfaceId);
    } 

    function _saveRoyalties(uint256 id, PartLib.PartData[] memory _royalties) internal {
        uint256 totalValue;
        for (uint i = 0; i < _royalties.length; i++) {
            require(_royalties[i].account != address(0x0), "Recipient should be present");
            require(_royalties[i].value != 0, "Royalty value should be positive");
            totalValue += _royalties[i].value;
            royalties[id].push(_royalties[i]);
        }
        require(totalValue < 10000, "Royalty total value should be < 10000");
        _onRoyaltiesSet(id, _royalties);
    }

    function _updateAccount(uint256 _id, address _from, address _to) internal {
        uint length = royalties[_id].length;
        for(uint i = 0; i < length; i++) {
            if (royalties[_id][i].account == _from) {
                royalties[_id][i].account = address(uint160(_to));
            }
        }
    }

    function _onRoyaltiesSet(uint256 id, PartLib.PartData[] memory _royalties) internal {
        emit RoyaltiesSet(id, _royalties);
    }
}