// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./UUPSUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./ERC1155BurnableUpgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";

contract HCARTEK221 is
    UUPSUpgradeable,
    ERC1155Upgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ERC1155BurnableUpgradeable,
    ERC1155HolderUpgradeable
{
    uint256 public MAIN_CONTRACT_ID;
    uint256 public MAIN_CONTRACT_SUPPLY;
    uint256 private NFT_SUPPLY;

    struct MEDIA_CONTENT {
        string ORIGINAL_IMAGE_BACK;
        string ORIGINAL_IMAGE_FRONT;
        string CERTIFICATE;
    }

    struct NFT {
        string ARTIST;
        string TITLE;
        string DATED;
        string DIMENSIONS;
        string TECHNIQUES;
        string SIGNATURE;
        string PREVIOUS_OWNER;
        string PROVENANCE;
        uint256 ID;
        uint256 RATIO;
        MEDIA_CONTENT CONTENT;
    }

    string public symbol;

    NFT public NFT01;
    NFT public NFT02;
    NFT public NFT03;

    string public LEGAL_CONTENT;

    bytes32 public BURNER_ROLE;
    bytes32 public MINTER_ROLE;

    address public contract_owner;

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    function initialize() public initializer {
        contract_owner = _msgSender();
        symbol = "HCARTEK221";

        MAIN_CONTRACT_SUPPLY = 1628 * (10**5);
        NFT_SUPPLY = 1;

        MAIN_CONTRACT_ID = 1;
        NFT01.ID = 2;
        NFT02.ID = 3;
        NFT03.ID = 4;

        NFT01.ARTIST = "Luiz Sacilotto";
        NFT02.ARTIST = "Luiz Sacilotto";
        NFT03.ARTIST = "Luiz Sacilotto";

        NFT01.TITLE = "Concrecao 8199";
        NFT02.TITLE = "Concrecao 8720";
        NFT03.TITLE = "Concrecao 9764";

        NFT01.DATED = "1981";
        NFT02.DATED = "1987";
        NFT03.DATED = "1997";

        NFT01.DIMENSIONS = "66 x 66 cm";
        NFT02.DIMENSIONS = "99 x 99 cm";
        NFT03.DIMENSIONS = "90 x 90 cm";

        NFT01.TECHNIQUES = "Tempera on wood";
        NFT02.TECHNIQUES = "Tempera on canvas";
        NFT03.TECHNIQUES = "Acrylic on canvas";

        NFT01.SIGNATURE = "Lower right";
        NFT02.SIGNATURE = "Lower right";
        NFT03.SIGNATURE = "Lower right";

        NFT01
            .CONTENT
            .ORIGINAL_IMAGE_BACK = "https://misc-files.hurst.capital/artwork/202112/HCARTEK221/back_nft01.pdf";
        NFT02
            .CONTENT
            .ORIGINAL_IMAGE_BACK = "https://misc-files.hurst.capital/artwork/202112/HCARTEK221/back_nft02.pdf";
        NFT03
            .CONTENT
            .ORIGINAL_IMAGE_BACK = "https://misc-files.hurst.capital/artwork/202112/HCARTEK221/back_nft03.pdf";

        NFT01
            .CONTENT
            .ORIGINAL_IMAGE_FRONT = "https://misc-files.hurst.capital/artwork/202112/HCARTEK221/front_nft01.pdf";
        NFT02
            .CONTENT
            .ORIGINAL_IMAGE_FRONT = "https://misc-files.hurst.capital/artwork/202112/HCARTEK221/front_nft02.pdf";
        NFT03
            .CONTENT
            .ORIGINAL_IMAGE_FRONT = "https://misc-files.hurst.capital/artwork/202112/HCARTEK221/front_nft03.pdf";

        NFT01.PREVIOUS_OWNER = "No";
        NFT02.PREVIOUS_OWNER = "No";
        NFT03.PREVIOUS_OWNER = "No";

        NFT01.PROVENANCE = "Valter Sacilotto";
        NFT02.PROVENANCE = "Valter Sacilotto";
        NFT03.PROVENANCE = "Valter Sacilotto";

        NFT01
            .CONTENT
            .CERTIFICATE = "https://misc-files.hurst.capital/artwork/202112/HCARTEK221/certificate_nft01.pdf";
        NFT02
            .CONTENT
            .CERTIFICATE = "https://misc-files.hurst.capital/artwork/202112/HCARTEK221/certificate_nft02.pdf";
        NFT03
            .CONTENT
            .CERTIFICATE = "https://misc-files.hurst.capital/artwork/202112/HCARTEK221/certificate_nft03.pdf";

        NFT01.RATIO = 3514;
        NFT02.RATIO = 3243;
        NFT03.RATIO = 3243;

        LEGAL_CONTENT = "https://misc-files.hurst.capital/artwork/202112/HCARTEK221/legal_content.pdf";

        MINTER_ROLE = keccak256("MINTER_ROLE");
        BURNER_ROLE = keccak256("BURNER_ROLE");

        _setupRole(MINTER_ROLE, contract_owner);
        _setupRole(BURNER_ROLE, contract_owner);
        _setupRole(DEFAULT_ADMIN_ROLE, contract_owner);

        _mint(contract_owner, MAIN_CONTRACT_ID, MAIN_CONTRACT_SUPPLY, "");
        _mint(contract_owner, NFT01.ID, NFT_SUPPLY, "");
        _mint(contract_owner, NFT02.ID, NFT_SUPPLY, "");
        _mint(contract_owner, NFT03.ID, NFT_SUPPLY, "");
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function burn(
        address account,
        uint256 tokenId,
        uint256 amount
    ) public override onlyRole(BURNER_ROLE) {
        _burn(account, tokenId, amount);
    }

    function adminBurnNft(uint256 tokenId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        burnNFT(tokenId);

        if (tokenId == NFT01.ID) {
            _burn(
                contract_owner,
                MAIN_CONTRACT_ID,
                (MAIN_CONTRACT_SUPPLY * NFT01.RATIO) / 10000
            );
        } else if (tokenId == NFT02.ID) {
            _burn(
                contract_owner,
                MAIN_CONTRACT_ID,
                (MAIN_CONTRACT_SUPPLY * NFT02.RATIO) / 10000
            );
        } else if (tokenId == NFT03.ID) {
            _burn(
                contract_owner,
                MAIN_CONTRACT_ID,
                (MAIN_CONTRACT_SUPPLY * NFT03.RATIO) / 10000
            );
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            AccessControlUpgradeable,
            ERC1155Upgradeable,
            ERC1155ReceiverUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function isTokenNFT(uint256 tokenId) internal view {
        bool checkToken = (tokenId >= NFT01.ID) && (tokenId <= NFT03.ID);

        require(
            checkToken,
            string(abi.encodePacked("tokenId is not an NFT ", checkToken))
        );
    }

    function burnNFT(uint256 tokenId) internal {
        isTokenNFT(tokenId);

        uint256 tokenBalance = balanceOf(contract_owner, tokenId);
        bool hasBalance = tokenBalance == NFT_SUPPLY;

        require(hasBalance, "not enough balance for the tokenId");

        _burn(contract_owner, tokenId, NFT_SUPPLY);
    }
}
