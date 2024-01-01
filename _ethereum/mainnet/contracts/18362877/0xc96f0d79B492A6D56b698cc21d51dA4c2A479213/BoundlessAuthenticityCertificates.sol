// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./AccessControl.sol";
import "./console.sol";

interface IBoundlessCertificateContract {
    function ownerOf(uint256 tokenId) external view returns (address);

    function smallPrints(uint256 tokenId) external view returns (bool);
}

contract BoundlessAuthenticityCertificates is AccessControl, ERC721Upgradeable {
    error NotTokenOwner();
    error CertificateContractOnly();

    event CertificateMinted(
        uint256 indexed tokenId,
        string indexed printSize,
        address indexed recipient
    );

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                             CONSTANTS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    address public constant BOUNDLESS_CERTIFICATE_CONTRACT =
        0x8A1c5ef2e999c57C37fd9327B6A8Dc5B76287e7f;
    address public constant GOERLI_BOUNDLESS_CERTIFICATE_CONTRACT =
        0xfc501FBBd30E0e89a76CB58CA0f3Fe54eCC67554;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                             STATE VARIABLES
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    address public boundlessVoucherAddress;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                             INITIALIZER
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _admin
    ) external initializer {
        __ERC721_init(_name, _symbol);
        _grantRole(COLLECTION_ADMIN_ROLE, _admin);
    }

    /* The token ID of the authenticity certificate will match the token ID of the boundless certificate voucher that is going to be burned. */
    function mint(uint256[] memory tokenIds) external {
        address receiver = tx.origin;

        if (msg.sender != getBoundlessVoucherAddress()) {
            revert CertificateContractOnly();
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            if (
                IBoundlessCertificateContract(getBoundlessVoucherAddress())
                    .ownerOf(tokenId) != receiver
            ) {
                revert NotTokenOwner();
            }

            _safeMint(receiver, tokenId);
            string memory printSize = getCertificatePrintSize(tokenId);

            emit CertificateMinted(tokenId, printSize, receiver);
        }
    }

    function getCertificatePrintSize(
        uint256 tokenId
    ) public view returns (string memory size) {
        if (
            IBoundlessCertificateContract(getBoundlessVoucherAddress())
                .smallPrints(tokenId)
        ) {
            return "small";
        } else {
            return "large";
        }
    }

    function setBoundlessVoucherAddress(address _address) external onlyAdmin {
        boundlessVoucherAddress = _address;
    }

    function getBoundlessVoucherAddress() public view returns (address) {
        if (boundlessVoucherAddress != address(0)) {
            return boundlessVoucherAddress;
        }
        if (block.chainid == 5) {
            return GOERLI_BOUNDLESS_CERTIFICATE_CONTRACT;
        }
        return BOUNDLESS_CERTIFICATE_CONTRACT;
    }
}
