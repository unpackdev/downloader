// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AccessControlEnumerable.sol";
import "./ReentrancyGuard.sol";
import "./EnumerableSet.sol";
import "./IInviting.sol";

/**
 * @title Initial Dex Offering
 * @author BEBE-TEAM
 * @notice Contract to supply IDO Tokens
 */
contract IDO is AccessControlEnumerable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    IInviting public inviting;

    mapping(uint256 => address) public idoTokens;
    mapping(uint256 => uint256) public tokenPrices;
    mapping(uint256 => address) public tokenAddrs;
    mapping(uint256 => address) public receivingAddrs;
    mapping(uint256 => uint256) public tokenMaxSupplys;
    mapping(uint256 => uint256) public startTimes;
    mapping(uint256 => uint256) public endTimes;
    mapping(uint256 => uint256[2]) public userBuyLimits;
    mapping(uint256 => uint256[2]) public ratios;
    mapping(uint256 => bool) public whiteListFlags;
    mapping(uint256 => bool) public invitingFlags;

    mapping(uint256 => uint256) public tokenSoldout;
    mapping(address => mapping(uint256 => uint256)) public userTokenPurchased;
    mapping(uint256 => EnumerableSet.AddressSet) private whiteList;

    event SetIDOInfo(
        uint256 idoId,
        address idoToken,
        uint256 tokenPrice,
        address tokenAddr,
        address receivingAddr,
        uint256 tokenMaxSupply,
        uint256 starTime,
        uint256 endTime,
        uint256[2] userBuyLimit,
        uint256[2] ratio,
        bool whiteListFlag,
        bool invitingFlag
    );
    event AddWhiteList(uint256 idoId, address[] whiteUsers);
    event RemoveWhiteList(uint256 idoId, address[] whiteUsers);
    event BuyToken(address indexed user, uint256 amount, uint256 idoId);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
    }

    /**
     * @dev Set Addrs
     */
    function setAddrs(address _inviting) external onlyRole(MANAGER_ROLE) {
        inviting = IInviting(_inviting);
    }

    /**
     * @dev Set IDO Info
     */
    function setIDOInfo(
        uint256 idoId,
        address idoToken,
        uint256 tokenPrice,
        address tokenAddr,
        address receivingAddr,
        uint256 tokenMaxSupply,
        uint256 startTime,
        uint256 endTime,
        uint256[2] calldata userBuyLimit,
        uint256[2] calldata ratio,
        bool whiteListFlag,
        bool invitingFlag
    ) external onlyRole(MANAGER_ROLE) {
        idoTokens[idoId] = idoToken;
        tokenPrices[idoId] = tokenPrice;
        tokenAddrs[idoId] = tokenAddr;
        receivingAddrs[idoId] = receivingAddr;
        tokenMaxSupplys[idoId] = tokenMaxSupply;
        startTimes[idoId] = startTime;
        endTimes[idoId] = endTime;
        userBuyLimits[idoId] = userBuyLimit;
        ratios[idoId] = ratio;
        whiteListFlags[idoId] = whiteListFlag;
        invitingFlags[idoId] = invitingFlag;

        emit SetIDOInfo(
            idoId,
            idoToken,
            tokenPrice,
            tokenAddr,
            receivingAddr,
            tokenMaxSupply,
            startTime,
            endTime,
            userBuyLimit,
            ratio,
            whiteListFlag,
            invitingFlag
        );
    }

    /**
     * @dev Add White List
     */
    function addWhiteList(
        uint256 idoId,
        address[] memory whiteUsers
    ) external onlyRole(MANAGER_ROLE) {
        for (uint256 i = 0; i < whiteUsers.length; i++) {
            whiteList[idoId].add(whiteUsers[i]);
        }

        emit AddWhiteList(idoId, whiteUsers);
    }

    /**
     * @dev Remove White List
     */
    function removeWhiteList(
        uint256 idoId,
        address[] memory whiteUsers
    ) external onlyRole(MANAGER_ROLE) {
        for (uint256 i = 0; i < whiteUsers.length; i++) {
            whiteList[idoId].remove(whiteUsers[i]);
        }

        emit RemoveWhiteList(idoId, whiteUsers);
    }

    /**
     * @dev Claim Token
     */
    function claimToken(
        address token,
        address user,
        uint256 amount
    ) external onlyRole(MANAGER_ROLE) {
        IERC20(token).safeTransfer(user, amount);
    }

    /**
     * @dev Users buy token
     */
    function buyToken(
        uint256 amount,
        uint256 idoId
    ) external payable nonReentrant {
        require(amount > 0, "Amount must > 0");
        require(
            idoTokens[idoId] != address(0),
            "The token of this IDO has not been set"
        );
        require(
            block.timestamp >= startTimes[idoId],
            "This IDO has not started"
        );
        require(block.timestamp <= endTimes[idoId], "This IDO has ended");
        require(getTokenLeftSupply(idoId) >= amount, "Not enough token supply");
        require(
            tokenPrices[idoId] > 0,
            "The price of this IDO has not been set"
        );
        require(
            receivingAddrs[idoId] != address(0),
            "The receiving address of this IDO has not been set"
        );
        if (whiteListFlags[idoId]) {
            require(
                whiteList[idoId].contains(msg.sender),
                "Your address must be on the whitelist"
            );
        }
        address inviter = inviting.userInviter(msg.sender);
        if (invitingFlags[idoId]) {
            require(inviter != address(0), "The inviter cannot be empty");
        }

        uint256 price = (amount * tokenPrices[idoId]) / 1e18;
        require(price >= userBuyLimits[idoId][0], "Price must >= min limit");
        require(
            getUserTokenLeftSupply(idoId, msg.sender) >= price,
            "Price exceeds the max limit"
        );
        if (tokenAddrs[idoId] == address(0)) {
            require(msg.value == price, "Price mismatch");
            payable(receivingAddrs[idoId]).transfer(price);
        } else {
            IERC20 token = IERC20(tokenAddrs[idoId]);
            token.safeTransferFrom(msg.sender, receivingAddrs[idoId], price);
        }

        IERC20(idoTokens[idoId]).safeTransfer(msg.sender, amount);

        if (inviting.userInviter(inviter) != address(0)) {
            IERC20(idoTokens[idoId]).safeTransfer(
                inviting.userInviter(inviter),
                (amount * ratios[idoId][1]) / 1e4
            );
        }

        if (inviter != address(0)) {
            IERC20(idoTokens[idoId]).safeTransfer(
                inviter,
                (amount * ratios[idoId][0]) / 1e4
            );
        }

        userTokenPurchased[msg.sender][idoId] += price;
        tokenSoldout[idoId] += amount;

        emit BuyToken(msg.sender, amount, idoId);
    }

    /**
     * @dev Get White List Existence
     */
    function getWhiteListExistence(
        uint256 idoId,
        address user
    ) external view returns (bool) {
        return whiteList[idoId].contains(user);
    }

    /**
     * @dev Get Token Left Supply
     */
    function getTokenLeftSupply(uint256 idoId) public view returns (uint256) {
        return tokenMaxSupplys[idoId] - tokenSoldout[idoId];
    }

    /**
     * @dev Get User Token Left Supply
     */
    function getUserTokenLeftSupply(
        uint256 idoId,
        address user
    ) public view returns (uint256) {
        return userBuyLimits[idoId][1] - userTokenPurchased[user][idoId];
    }
}
