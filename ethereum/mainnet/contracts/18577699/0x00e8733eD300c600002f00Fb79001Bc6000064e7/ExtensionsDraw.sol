// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC1155Burnable.sol";
import "./IERC1155Transfer.sol";
import "./IERC721Transfer.sol";
import "./IERC20Transfer.sol";

import "./Ownable.sol";

interface IExtensions is IERC1155Burnable, IERC1155Transfer {}

struct Submission {
    address owner;
    uint96 balance;
}

contract ExtensionsDraw is Ownable {
    error SubmissionsPaused();
    error InvalidExtensionId();
    error InvalidQuantity();
    error ArrayLengthMismatch();
    error NoSubmissionForUser();
    error CantRecoverSubmittedTokens();
    error NotTokenSubmission();

    event Winners(uint256 indexed extensionId, uint256 indexed round, address[] winners);

    IExtensions public immutable EXTENSIONS;

    uint248 public validTokenIds;
    bool public submissionEnabled;

    // Current round for each extension
    mapping(uint256 => uint256) public currentRound;

    // Users committed to extension mapping
    mapping(uint256 => Submission[]) public submissionsByExtension;

    // Mapping of user => extension id => submission index
    mapping(address => mapping(uint256 => uint256)) private submissionIndex;

    constructor(address extensions) {
        EXTENSIONS = IExtensions(extensions);
        _initializeOwner(tx.origin);

        currentRound[1] = 4; // 3 video extensions already allocated
        currentRound[2] = 2; // 2 music extensions already allocated
        currentRound[3] = 3; // 2 toy extensions already allocated
        currentRound[4] = 1; // 0 game extensions already allocated

        validTokenIds = 15;
    }

    /**
     * @notice Submit an extension to the contract for drawing in the next round. Extensions must be
     * approved for transfer by the contract.
     * @param extensionId The ID of the extension to submit.
     * @param quantity The quantity of the extension to submit.
     */
    function submit(uint256 extensionId, uint96 quantity) external {
        if (!submissionEnabled) {
            revert SubmissionsPaused();
        }

        createOrUpdateSubmission(extensionId, quantity);

        EXTENSIONS.safeTransferFrom(msg.sender, address(this), extensionId, quantity, "");
    }

    function batchSubmit(uint256[] calldata extensionIds, uint256[] calldata quantities) external {
        if (!submissionEnabled) {
            revert SubmissionsPaused();
        }

        uint256 length = extensionIds.length;
        if (length != quantities.length) {
            revert ArrayLengthMismatch();
        }

        for (uint256 i; i < length;) {
            createOrUpdateSubmission(extensionIds[i], uint96(quantities[i]));

            unchecked {
                ++i;
            }
        }

        EXTENSIONS.safeBatchTransferFrom(msg.sender, address(this), extensionIds, quantities, "");
    }

    function createOrUpdateSubmission(uint256 extensionId, uint96 quantity) private {
        if (!isValidTokenId(extensionId)) {
            revert InvalidExtensionId();
        }
        if (quantity == 0) {
            revert InvalidQuantity();
        }

        uint256 userSubmissionIndex = submissionIndex[msg.sender][extensionId];
        unchecked {
            if (userSubmissionIndex == 0) {
                submissionsByExtension[extensionId].push(Submission(msg.sender, quantity));
                uint256 newIndex = submissionsByExtension[extensionId].length;
                // storing 1 based index to delineate between first item and no item in the array
                submissionIndex[msg.sender][extensionId] = newIndex;
            } else {
                // use the 1 based index to get the submission from the array
                Submission storage submission =
                    submissionsByExtension[extensionId][userSubmissionIndex - 1];
                submission.balance = uint96(submission.balance + quantity);
            }
        }
    }

    /**
     * @notice Revoke all submissions for a specific extension id. The user must have a submission
     * for the extension. All tokens will be returned to the user.
     * @param extensionId The ID of the extension to revoke.
     */
    function revokeSubmission(uint256 extensionId) external {
        uint256 balance = removeUserSubmission(extensionId);
        EXTENSIONS.safeTransferFrom(address(this), msg.sender, extensionId, balance, "");
    }

    function batchRevokeSubmissions(uint256[] calldata extensionIds) external {
        uint256 length = extensionIds.length;
        uint256[] memory balances = new uint256[](length);
        for (uint256 i; i < length;) {
            uint256 extensionId = extensionIds[i];
            balances[i] = removeUserSubmission(extensionId);
            unchecked {
                ++i;
            }
        }

        EXTENSIONS.safeBatchTransferFrom(address(this), msg.sender, extensionIds, balances, "");
    }

    function removeUserSubmission(uint256 extensionId) private returns (uint256) {
        if (!isValidTokenId(extensionId)) {
            revert InvalidExtensionId();
        }
        uint256 rawSubmissionIndex = submissionIndex[msg.sender][extensionId];
        if (rawSubmissionIndex == 0) {
            revert NoSubmissionForUser();
        }

        // user submission index is 1 based, so decrement to get the index in the array
        uint256 userSubmissionIndex = rawSubmissionIndex - 1;

        Submission[] storage submissions = submissionsByExtension[extensionId];
        uint256 balance = submissions[userSubmissionIndex].balance;

        if (rawSubmissionIndex < submissions.length) {
            submissions[userSubmissionIndex] = submissions[submissions.length - 1];
        }
        submissions.pop();
        // clear the submission index for the user
        delete submissionIndex[msg.sender][extensionId];

        return balance;
    }

    /**
     * @notice Set whether or not submissions are enabled for the contract.
     */
    function setSubmissionEnabled(bool enabled) external onlyOwner {
        submissionEnabled = enabled;
    }

    /**
     * @notice Enable a token id for submission.
     * @param tokenId The ID of the token to enable.
     */
    function enableTokenId(uint248 tokenId) external onlyOwner {
        if (tokenId > 255) {
            revert InvalidExtensionId();
        }
        if (!isValidTokenId(tokenId)) {
            currentRound[tokenId] = 1;
            validTokenIds |= uint248(1 << (tokenId - 1));
        }
    }

    /**
     * @dev Draw winners for a given extension ID. The number of winners drawn is the minimum of the
     * number of submissions and the maxWinners parameter.
     * @param extensionId The ID of the extension to draw winners for.
     * @param maxWinners The maximum number of winners to draw.
     */
    function draw(uint256 extensionId, uint256 maxWinners) external onlyOwner {
        if (maxWinners == 0) {
            revert InvalidQuantity();
        }
        Submission[] storage submissions = submissionsByExtension[extensionId];
        uint256 length = submissions.length;

        uint256 startIndex;
        if (length < maxWinners) {
            maxWinners = length;
        } else {
            startIndex = _random(length);
        }

        processDraw(extensionId, maxWinners, startIndex, submissions);

        EXTENSIONS.burn(address(this), extensionId, maxWinners);
    }

    /**
     * @dev Processes a draw for a given token ID, selecting `winners` number of winners from the
     * `submissions` array starting at `startIndex`. decrements the balance of each selected
     * submission by 1, and removes any submission with a balance of 0 from the array.
     * If a submission is removed, swaps it with the last element of the array and pops
     * it off the end. Emits a `Winner` event for each selected submission, containing the token ID,
     * the current extension round, and the owner of the submission.
     * @param tokenId The ID of the token for which to process the draw.
     * @param winners The number of winners to select from the submissions array.
     * @param startIndex The index of the first submission to consider in the submissions array.
     * @param submissions The array of submissions to select winners from.
     */
    function processDraw(
        uint256 tokenId,
        uint256 winners,
        uint256 startIndex,
        Submission[] storage submissions
    ) internal {
        unchecked {
            address[] memory winnersArray = new address[](winners);

            uint256 extensionRound = currentRound[tokenId];
            currentRound[tokenId] = extensionRound + 1;

            uint256 length = submissions.length;

            uint256 index = startIndex;
            for (uint256 i; i < winners;) {
                Submission memory submission = submissions[index];

                winnersArray[i] = submission.owner;
                // if the submission would be decremented to a balance of 0, swap in the last element
                // of the array and pop it off the end, otherwise decrement the balance
                if (submission.balance == 1) {
                    // clear the submission index for the user
                    delete submissionIndex[submission.owner][tokenId];

                    --length;

                    if (index < length) {
                        Submission memory lastItem = submissions[length];
                        submissions[index] = lastItem;
                        submissionIndex[lastItem.owner][tokenId] = (index + 1);
                    }
                    submissions.pop();
                } else {
                    submissions[index].balance = submission.balance - 1;
                    ++index;
                }

                ++i;
                if (index >= length) {
                    index = 0;
                }
            }

            emit Winners(tokenId, extensionRound, winnersArray);
        }
    }

    /**
     * @notice Returns the submission index of a user for a given token ID.
     * @param user The address of the user.
     * @param tokenId The ID of the token.
     * @return index of the user's submission record for the given token ID.
     */
    function getSubmissionIndex(address user, uint256 tokenId) external view returns (uint256) {
        uint256 index = submissionIndex[user][tokenId];
        if (index == 0) {
            revert NoSubmissionForUser();
        }
        return index - 1;
    }

    /**
     * @notice Returns an array of all submissions for a given token ID.
     * @param tokenId The ID of the token.
     * @return submissions for the given token ID.
     */
    function getAllSubmissions(uint256 tokenId) external view returns (Submission[] memory) {
        return submissionsByExtension[tokenId];
    }

    /**
     * @notice Generates a random number between 0 and max (exclusive).
     * @param max The maximum value of the random number (exclusive).
     * @return random number between 0 and max (exclusive).
     */
    function _random(uint256 max) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao))) % max;
    }

    /**
     * @notice Checks if a given token ID is valid.
     * @param tokenId The ID of the token.
     * @return True if the token ID is valid, false otherwise.
     */
    function isValidTokenId(uint256 tokenId) internal view returns (bool) {
        if (tokenId == 0) {
            return false;
        }

        return (1 << (tokenId - 1) & validTokenIds) != 0;
    }

    function recoverERC721(address token, uint256 tokenId) external onlyOwner {
        IERC721Transfer(token).transferFrom(address(this), msg.sender, tokenId);
    }

    function recoverERC20(address token, uint256 amount) external onlyOwner {
        IERC20Transfer(token).transfer(msg.sender, amount);
    }

    /**
     * @notice Handle the receipt of a single ERC1155 token type.
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.
     * This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
     * This function MUST revert if it rejects the transfer.
     * Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(address operator, address, uint256, uint256, bytes calldata)
        external
        view
        returns (bytes4)
    {
        if (operator != address(this)) {
            revert NotTokenSubmission();
        }
        return 0xf23a6e61;
    }

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external view returns (bytes4) {
        if (operator != address(this)) {
            revert NotTokenSubmission();
        }
        return 0xbc197c81;
    }
}
