// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC20.sol";
import "./Owned.sol";
import "./ReentrancyGuard.sol";

/// @title QuestionExchange
/// @notice A contract allowing users to pay to have questions answered by other users
contract QuestionExchange is Owned, ReentrancyGuard {
    /// fee percentage up to 2 decimal places (1% = 100, 0.1% = 10, 0.01% = 1)
    uint8 public feePercentage;
    address public feeReceiver;

    struct Question {
        uint256 replyTo;
        string questionUrl;
        string answerUrl;
        address bidToken;
        uint256 bidAmount;
        uint256 expiresAt;
        uint256 askedAt;
        address asker;
        uint256 expiryClaimedAt;
        uint256 answeredAt;
        bool isPrivate;
    }

    mapping(address => mapping(uint256 => Question)) public questions;
    mapping(address => uint256) public questionCounts;
    mapping(address => string) public profileUrls;

    mapping(address => uint256) public lockedAmounts;
    /// @notice emitted when a question is asked
    event Asked(
        address indexed answerer,
        address indexed asker,
        uint256 indexed questionId
    );

    /// @notice emitted when a question is answered
    event Answered(
        address indexed answerer,
        address indexed asker,
        uint256 indexed questionId
    );

    /// @notice emitted when a question is expired
    event Expired(
        address indexed answerer,
        address indexed asker,
        uint256 indexed questionId
    );

    /// @notice thrown when providing an empty question
    error EmptyQuestion();

    /// @notice thrown when answering a question that is already answered
    error AlreadyAnswered();

    /// @notice thrown when attempting to expire a question is answered or not yet expired
    error NotExpired();

    /// @notice thrown when attempting to claim an expired question that is already claimed
    error ExpiryClaimed();

    /// @notice thrown when answering a question that is expired
    error QuestionExpired();

    /// @notice thrown when providing an empty answer
    error EmptyAnswer();

    /// @notice thrown when attempting to expire a question that sender did not ask
    error NotAsker();

    /// @notice thrown when attempting to send ETH to this contract via fallback method
    error FallbackNotPayable();
    
    /// @notice thrown when attempting to send ETH to this contract via receive method
    error ReceiveNotPayable();

    constructor(uint8 _feePercentage) Owned(msg.sender) {
        feePercentage = _feePercentage;
        feeReceiver = owner;
    }

    function ask(
        address answerer, 
        string memory questionUrl, 
        address bidToken, 
        uint256 bidAmount,
        uint256 replyTo,
        uint256 expiresAt,
        bool isPrivate
    ) public nonReentrant {
        uint256 nextQuestionId = questionCounts[answerer];
        questionCounts[answerer] = nextQuestionId + 1;

        questions[answerer][nextQuestionId] = Question({
            replyTo: replyTo,
            questionUrl: questionUrl,
            bidToken: bidToken,
            bidAmount: bidAmount,
            expiresAt: expiresAt,
            askedAt: block.timestamp,
            asker: msg.sender,
            isPrivate: isPrivate,
            expiryClaimedAt: 0,
            answeredAt: 0,
            answerUrl: ''
        });

        emit Asked(answerer, msg.sender, nextQuestionId);

        if(bidAmount != 0) {
            lockedAmounts[bidToken] += bidAmount;

            ERC20(bidToken).transferFrom(msg.sender, address(this), bidAmount);
        }
    }

    function expire(
        address answerer,
        uint256 questionId
    ) public nonReentrant {
        Question storage question = questions[answerer][questionId];
        if(question.askedAt == 0) revert EmptyQuestion();
        if(question.answeredAt != 0) revert AlreadyAnswered();
        if(question.expiresAt > block.timestamp) revert NotExpired();
        if(question.expiryClaimedAt != 0) revert ExpiryClaimed();
        if(question.asker != msg.sender) revert NotAsker();

        question.expiryClaimedAt = block.timestamp;
        emit Expired(answerer, msg.sender, questionId);
        
        if(question.bidAmount != 0) {
            lockedAmounts[question.bidToken] -= question.bidAmount;

            uint256 feeAmount = question.bidAmount * feePercentage / 10000; // feePercentage is normalised to 2 decimals
            ERC20(question.bidToken).transfer(question.asker, question.bidAmount - feeAmount);
            ERC20(question.bidToken).transfer(feeReceiver, feeAmount);
        }
    }

    function answer(
        uint256 questionId,
        string memory answerUrl
    ) public nonReentrant {
        Question storage question = questions[msg.sender][questionId];
        if(question.askedAt == 0) revert EmptyQuestion();
        if(question.answeredAt != 0) revert AlreadyAnswered();
        if(question.expiresAt <= block.timestamp) revert QuestionExpired();

        question.answerUrl = answerUrl;
        question.answeredAt = block.timestamp;

        emit Answered(msg.sender, question.asker, questionId);

        if(question.bidAmount != 0) {
            lockedAmounts[question.bidToken] -= question.bidAmount;

            uint256 feeAmount = question.bidAmount * feePercentage / 10000; // feePercentage is normalised to 2 decimals
            ERC20(question.bidToken).transfer(msg.sender, question.bidAmount - feeAmount);
            ERC20(question.bidToken).transfer(feeReceiver, feeAmount);
        }
    }

    function setFeePercentage(uint8 newFeePercentage) public onlyOwner {
        feePercentage = newFeePercentage;
    }

    function setFeeReceiver(address newFeeReceiver) public onlyOwner {
        feeReceiver = newFeeReceiver;
    }

    function setProfileUrl(string memory newProfileUrl) public {
        profileUrls[msg.sender] = newProfileUrl;
    }

    function rescueTokens(address tokenAddress) public {
        uint256 totalBalance = ERC20(tokenAddress).balanceOf(address(this));

        ERC20(tokenAddress).transfer(owner, totalBalance - lockedAmounts[tokenAddress]);
    }

    /// @notice prevents ETH being sent directly to this contract
    fallback() external {
        // ETH received with no msg.data
        revert FallbackNotPayable();
    }

    /// @notice prevents ETH being sent directly to this contract
    receive() external payable {
        // ETH received with msg.data that does not match any contract function
        revert ReceiveNotPayable();
    }
}
