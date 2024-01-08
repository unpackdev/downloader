// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: Slimesunday
/// @author: manifold.xyz

import "./AdminControl.sol";
import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";

import "./ERC165Checker.sol";
import "./IERC721.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                   //
//                                                                                                   //
//       ____  __________  __    ___   ____________            ____  __________  _________  ______   //
//      / __ \/ ____/ __ \/ /   /   | / ____/ ____/           / __ \/ ____/ __ \/ ____/   |/_  __/   //
//     / /_/ / __/ / /_/ / /   / /| |/ /   / __/    ______   / /_/ / __/ / /_/ / __/ / /| | / /      //
//    / _, _/ /___/ ____/ /___/ ___ / /___/ /___   /_____/  / _, _/ /___/ ____/ /___/ ___ |/ /       //
//   /_/ |_/_____/_/   /_____/_/  |_\____/_____/           /_/ |_/_____/_/   /_____/_/  |_/_/        //
//                                                                                                   //
//                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////

contract ReplaceAndRepeat is AdminControl, ICreatorExtensionTokenURI {

    string constant private _ASSET_TAG = '<ASSET>';
    string constant private _ASSET_TYPE_TAG = '<ASSET_TYPE_TAG>';
    string constant private _CONFIGURATOR_TAG = '<CONFIGURATOR>';
    string[] private _uriParts;

    address private _creator;
    uint256 private _tokenId;

    string private _assetPrefix;
    string[] private _assetPaths;
    string[] private _assetThumbnailPaths;
    uint256 private _assetPathIndex;
    string private _assetPathType;
    string private _assetConfigurator;

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || super.supportsInterface(interfaceId);
    }

    function activate(address creator) public adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(IERC721CreatorCore).interfaceId), "Requires creator to implement IERC721CreatorCore");
        require(_creator == address(0), "Already active");

        _uriParts = [
                     'data:application/json;utf8,{"name":"Replace & Repeat", "created_by":"Slimesunday", "description":"Collages created by the artist Slimesunday with found objects and Photoshop. Each object was hand selected at local antique shops and curated to fit the original photograph. The work features Diana Merimskaia photographed by Jordan Knight. Cycling through several different stills, the NFT owner has the ability to switch between the looping state and each individual state. Slimesunday will repeat the process of replacing portions of the original nude photograph to produce new stills that will be periodically added to the smart contract. As the piece evolves the owner possesses even more options to choose from for display. From Slimesunday\'s \\"What the Fork?\\" collection.", ',
                     '"','<ASSET_TYPE_TAG>','":"', '<ASSET>','", ',
                     '"','<ASSET_TYPE_TAG>','_url":"', '<ASSET>','", ',
                     '"credits":{"artist":"Slimesunday","photographer":"Jordan Knight","photography_assistant":"Khaliah Pianta","model":"Diana Merimskaia","hair":"Fara Conley","makeup":"Fara Conley","wardrobe":"Ali Mullin","wardrobe_assistant":"Nora Foley","production_designer":"Elizabeth Pearlman","producer":"Jori Teplitzky","production_manager":"Maya Klabin","production_assistant":"Etienne Smith"}, '
                     '"attributes":[{"trait_type":"Artist","value":"Slimesunday"},{"trait_type":"Collection","value":"What the Fork?"},{"trait_type":"Auctioneer","value":"Phillips"}]}'
                    ];

        _creator = creator;
        _assetPrefix = 'https://arweave.net/';
        _assetPaths = [
                    'up3NurCS2DdhbeprXX0iGDo5TVy3USiimyfMce7bn6w',
                    'L1k4gYGfvM2KPAwupPXUQBE283ScXke_oTsLSlyfMdE',
                    'u_9wgtUIzoKAeyp8axEC6GlpBunEQNLfz1bsvHhSrLI',
                    'e_DBHhevXR9FGlxG6CPNUhQJ8Ukmo0XckijISoULBzA',
                    '4Tvtbs42WrRT-J0DcF-YdsSyiOgv9fJPVLKuSnt3wYw',
                    'XF02DEylyxJOc_wlIcnuzHMgGxIUYwJRj5okLidPdsY',
                    '5mFOSMAnuCTrDRavok84Tm3z-00JMwGUHBgg5aVOTtQ',
                    'z4PIQY4yQ43gs7JRTTblKR2-CKuZAsod90Z7nKF8CD0',
                    'f-rMn0W9fbJQzngh9a-K7Xz6MDgCwmGojr3DeU6cUX4',
                    'Yn_XUKCa_aNxdr8Lto4bhI3ZuXJHBq3yfD9yn7DE7GA',
                    'AqMoSMb9jNQS4cDcNJ6MOig2Dw_Nod-Q6btF6zjeKu0',
                    'O5nV2CX8n3jAROFYx94FEsUN8fVCY8LVB9m999hcY9Y',
                    'CrDDI13A-d4brFKcLAUy06CtxIexruM_Z_4Wja7ffWc',
                    '8fGL-De7E8YkQUZCIqhni-L8XimmC-ONXrYaD5MPw30',
                    'eVj_MTRcoSDpVFHvqt6uJBatMOgocU76Omtc1Z8W7-4',
                    '96Zys33QV0-5puSFKD9FUfSvuJkymtl5N4doEKiWtcA'
                    ];
        _assetThumbnailPaths = [
                    'Lxf-Rp123_3HF3zFSZqNZCs-Wwm9fvXN84qflmvV40k',
                    'SL1SQmK189xxnp9RYpCkGmfJoOcjTmULnC_hIhc9B_g',
                    'rogYpmu1c46w9xfXW-Vf6Y3nUavkXVMQf_eh0wqMsOw',
                    'VQ3UJuTCtb7S2nMFvJCUas1_vSoEtz9h8q6vrF28zsc',
                    'OnkgYdBD59Fk7JMxzsyxMgyVI8XnVqUWjJ6m5hNtqA8',
                    'Ui97kYfh37vKLGm3GMXd8yYvkwuRZcH5Ij4K3OXSTJY',
                    'C8G3lCRccYsXpYAvkUyvOTd8MlPKEHd1rT6aV_mlC3E',
                    'DwO66iYLUKcGAsTC6WE6Ue__wS3uQF8DP-tkOQoih9o',
                    '9jen0YJ9-HZPMFT_zlTmBTQQQIscWEFOlTAROwFM8lc',
                    'Wp4RGTZiE3L86OkTiMKySb8USQ3tlOwTO0W9-58UFUY',
                    'EAnT9vupqUTYfsDCgRRYHSjdm3pLTobj06O3LKazmW8',
                    'w5Jaizo1HToHHhobf71tG8OuTGqWuWnhd3x1z1xV1g8',
                    'x4Ad9QUzetdKk3_TswNEZr9SQnFIDxmiyzuwDfdUWyA',
                    'FQxmGowmJSwr5KMugv-6KC76_Xw1DO0hVFNoaPmldbI',
                    'i-Iz0agCc_WZbAQScSIW_08IwlYhZbS6EwmXw8U211M',
                    'z1h3o6xNq1GtT5zACEn5RX-bkcs7vHppop_V6E03MqU'
                    ];
        _tokenId = IERC721CreatorCore(_creator).mintExtension(owner());

    }

    /**
     * @dev See {ICreatorExtensionTokenURI-tokenURI}.
     */
    function tokenURI(address creator_, uint256 tokenId) external view override returns (string memory) {
        require(creator_ == _creator && tokenId == _tokenId, "Invalid token");
        return _generateURI();
    }

    /**
     * @dev update the asset location prefix
     */
    function setAssetPrefix(string calldata prefix) external adminRequired {
        _assetPrefix = prefix;
    }

    /**
     * @dev update the asset configurator location
     */
    function setAssetConfigurator(string calldata configurator) external adminRequired {
        _assetConfigurator = configurator;
    }

    /**
     * @dev update the URI data
     */
    function updateURIParts(string[] memory uriParts) public adminRequired {
        _uriParts = uriParts;
    }

    /**
     * @dev add asset
     */
    function addAsset(string memory assetPath, string memory assetThumbnailPath) public adminRequired {
        _assetPaths.push(assetPath);
        _assetThumbnailPaths.push(assetThumbnailPath);
    }

    /**
     * @dev get asset prefix
     */
    function getAssetPrefix() public view returns (string memory) {
        return _assetPrefix;
    }

    /**
     * @dev get current asset path index
     */
    function getAssetPathIndex() public view returns (uint256) {
       return _assetPathIndex;
    }

    /**
     * @dev get asset configurator
     */
    function getAssetConfigurator() public view returns (string memory) {
        return _assetConfigurator;
    }

    /**
     * @dev get asset path
     */
    function getAssetPath(uint256 index) public view returns (string memory) {
        require(index < _assetPaths.length, "Invalid index");
        return _assetPaths[index];
    }

    /**
     * @dev get asset paths
     */
    function getAssetPaths() public view returns (string[] memory) {
        return _assetPaths;
    }

    /**
     * @dev get asset thumbnail paths
     */
    function getAssetThumbnailPaths() public view returns (string[] memory) {
        return _assetThumbnailPaths;
    }

    /**
     * @dev remove asset
     */
    function removeAsset(uint256 index) public adminRequired {
        require(index < _assetPaths.length, "Invalid index");
        for (uint i = index; i < _assetPaths.length-1; i++) {
            _assetPaths[i] = _assetPaths[i+1];
            _assetThumbnailPaths[i] = _assetThumbnailPaths[i+1];
        }
        _assetPaths.pop();
        _assetThumbnailPaths.pop();
        if (index == _assetPathIndex) {
            _assetPathIndex = 0;
        }
    }

    /**
     * @dev set current asset path index
     */
    function setAssetPathIndex(uint256 index, string memory type_) public {
        require(IERC721(_creator).ownerOf(_tokenId) == msg.sender, "Only owner can update");
        require(index < _assetPaths.length, "Invalid index");
        _assetPathIndex = index;
        _assetPathType = type_;
    }

    function _generateURI() private view returns (string memory) {
        bytes memory byteString;
        for (uint i = 0; i < _uriParts.length; i++) {
            if (_checkTag(_uriParts[i], _ASSET_TAG)) {
                byteString = abi.encodePacked(byteString, _assetPrefix, _assetPaths[_assetPathIndex]);
            } else if (_checkTag(_uriParts[i], _ASSET_TYPE_TAG)) {
                byteString = abi.encodePacked(byteString, _assetPathType);
            } else if (_checkTag(_uriParts[i], _CONFIGURATOR_TAG)) {
                byteString = abi.encodePacked(byteString, _assetConfigurator);
            } else {
                byteString = abi.encodePacked(byteString, _uriParts[i]);
            }
        }
        return string(byteString);
    }    

    function _checkTag(string storage a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

}