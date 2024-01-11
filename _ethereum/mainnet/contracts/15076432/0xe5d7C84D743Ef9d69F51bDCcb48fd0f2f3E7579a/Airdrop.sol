//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC165Checker.sol";
import "./IERC165.sol";
import "./IERC1155.sol";
import "./IERC721.sol";

import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract Airdrop is Ownable, ReentrancyGuard {
    bool private _paused;
    string private _name;

    bytes4 public constant ERC721ID = type(IERC721).interfaceId;
    bytes4 public constant ERC1155ID = type(IERC1155).interfaceId;

    error ERC165InterfaceError();
    error ApprovalError();
    error ArraySizeError();
    error PausedError();

    function name() external view returns (string memory) {
        return _name;
    }

    function setName(string memory newName) external onlyOwner {
        _name = newName;
    }

    function getPaused() external view returns (bool) {
        return _paused;
    }

    function setPaused(bool paused) external onlyOwner {
        _paused = paused;
    }

    function isContractERC165(address targetContract)
        public
        view
        returns (bool)
    {
        return ERC165Checker.supportsERC165(targetContract);
    }

    function isContractERC1155(address targetContract)
        public
        view
        returns (bool)
    {
        return ERC165Checker.supportsInterface(targetContract, ERC1155ID);
    }

    function isContractERC721(address targetContract)
        public
        view
        returns (bool)
    {
        return ERC165Checker.supportsInterface(targetContract, ERC721ID);
    }

    function doAirdrop(
        address targetContract,
        address[] memory accounts,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external nonReentrant {
        if (_paused) {
            revert PausedError();
        }

        bool isERC165 = isContractERC165(targetContract);
        if (!isERC165) {
            revert ERC165InterfaceError();
        }

        bool isERC1155 = isContractERC1155(targetContract);
        if (isERC1155) {
            bool isApproved = IERC1155(targetContract).isApprovedForAll(
                msg.sender,
                address(this)
            );

            if (!isApproved) {
                revert ApprovalError();
            }

            _doAirdropIERC1155(targetContract, accounts, tokenIds, amounts);
            return;
        }

        bool isERC721 = isContractERC721(targetContract);
        if (isERC721) {
            bool isApproved = IERC721(targetContract).isApprovedForAll(
                msg.sender,
                address(this)
            );
            if (!isApproved) {
                revert ApprovalError();
            }

            _doAirdropIERC721(targetContract, accounts, tokenIds);
        }
    }

    function _doAirdropIERC1155(
        address targetContract,
        address[] memory accounts,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) internal {
        if (
            accounts.length == 0 ||
            tokenIds.length == 0 ||
            tokenIds.length != amounts.length
        ) {
            revert ArraySizeError();
        }

        for (uint256 i = 0; i < accounts.length; i++) {
            IERC1155(targetContract).safeBatchTransferFrom(
                msg.sender,
                accounts[i],
                tokenIds,
                amounts,
                ""
            );
        }
    }

    function _doAirdropIERC721(
        address targetContract,
        address[] memory accounts,
        uint256[] memory tokenIds
    ) internal {
        if (
            accounts.length == 0 ||
            tokenIds.length == 0 ||
            accounts.length != tokenIds.length
        ) {
            revert ArraySizeError();
        }

        for (uint256 i = 0; i < accounts.length; i++) {
            IERC721(targetContract).safeTransferFrom(
                msg.sender,
                accounts[i],
                tokenIds[i]
            );
        }
    }
}

// ╔════════════════════╗
// ║   Smart Contract   ║
// ║         by         ║
// ║     King Tide      ║
// ╚════════════════════╝
