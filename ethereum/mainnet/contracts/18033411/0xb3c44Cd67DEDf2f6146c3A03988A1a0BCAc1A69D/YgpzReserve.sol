// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "./Strings.sol";
import "./EnumerableSet.sol";
import "./Math.sol";
import "./ECDSA.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

// import "./console.sol";

contract YgpzReserve is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;

    address public signer;
    // uint256 public depositedTotal;
    uint256 public reserveState;

    // EnumerableSet.AddressSet depositedUsers;
    mapping(address => uint256) public userDepositedETH;
    mapping(address => bool) public isUserRefunded;

    uint256 public totalAcceptedBidsInETH;
    uint256 public withdrawed;
    bool public canPublicDeposit;

    uint256 public priceT1;
    uint256 public priceT2;
    uint256 public priceT3;

    event UserReserve(
        address indexed user,
        uint256 amount,
        uint256 t1,
        uint256 t2,
        uint256 t3
    );
    event UserUpgradeReserve(
        address indexed user,
        uint256 amount,
        uint256 fromT2toT1,
        uint256 fromT3toT1,
        uint256 fromMNPLtoT1
    );
    event UserRefunded(address indexed user, uint256 acceptedBidsInETH);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _signer) public initializer {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        OwnableUpgradeable.__Ownable_init();
        signer = _signer;
    }

    function checkValidity(
        bytes calldata signature,
        string memory action
    ) public view returns (bool) {
        require(
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(
                    keccak256(abi.encodePacked(msg.sender, action))
                ),
                signature
            ) == signer,
            "invalid signature"
        );
        return true;
    }

    function reservePrice(
        uint256 t1,
        uint256 t2,
        uint256 t3
    ) public view returns (uint256) {
        return (t1 * priceT1) + (t2 * priceT2) + (t3 * priceT3);
    }

    function reserve(
        uint256 t1,
        uint256 t2,
        uint256 t3,
        bytes calldata signature
    ) external payable {
        require(reserveState == 1, "Reservation not open");
        require(msg.value > 0, "msg.value must be > 0");
        if (!canPublicDeposit) {
            checkValidity(signature, "ygpz-deposit");
        }
        // console.log(msg.value);
        // console.log(reservePrice(t1, t2, t3));

        require(reservePrice(t1, t2, t3) == msg.value, "Incorrect msg.value");
        // depositedTotal += msg.value;
        userDepositedETH[msg.sender] += msg.value;
        // depositedUsers.add(msg.sender);
        emit UserReserve(msg.sender, msg.value, t1, t2, t3);
    }

    function upgradePrice(
        uint256 fromT2toT1,
        uint256 fromT3toT1,
        uint256 fromMNPLtoT1
    ) public view returns (uint256) {
        return
            ((priceT1 - priceT2) * fromT2toT1) +
            ((priceT1 - priceT3) * fromT3toT1) +
            (priceT1 * fromMNPLtoT1);
    }

    function upgradeReserve(
        uint256 fromT2toT1,
        uint256 fromT3toT1,
        uint256 fromMNPLtoT1
    ) external payable {
        require(reserveState == 1, "Reservation not open");
        require(msg.value > 0, "msg.value must be > 0");
        require(
            (fromT2toT1 == 0 && fromT3toT1 == 0) ||
                userDepositedETH[msg.sender] > 0,
            "No reservation deposit record"
        );
        require(
            upgradePrice(fromT2toT1, fromT3toT1, fromMNPLtoT1) == msg.value,
            "Incorrect msg.value"
        );
        // depositedTotal += msg.value;
        userDepositedETH[msg.sender] += msg.value;
        // depositedUsers.add(msg.sender);

        emit UserUpgradeReserve(
            msg.sender,
            msg.value,
            fromT2toT1,
            fromT3toT1,
            fromMNPLtoT1
        );
    }

    function refund(
        uint256 acceptedBidsInETH,
        bytes calldata signature
    ) external nonReentrant {
        require(reserveState == 3, "Reservation not in finished state");
        require(
            userDepositedETH[msg.sender] > 0,
            "No reservation deposit record"
        );
        require(!isUserRefunded[msg.sender], "Already refunded");
        string memory action = string.concat(
            "ygpz-refund-accepted-",
            Strings.toString(acceptedBidsInETH)
        );
        checkValidity(signature, action);
        uint256 refundAvailable = userDepositedETH[msg.sender] -
            acceptedBidsInETH;
        require(refundAvailable > 0, "Nothing to refund");
        isUserRefunded[msg.sender] = true;
        emit UserRefunded(msg.sender, acceptedBidsInETH);

        _withdraw(msg.sender, refundAvailable);
    }

    // =============== Admin ===============
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function withdrawSales() public onlyOwner {
        require(totalAcceptedBidsInETH > 0, "totalAcceptedBidsInETH not set");

        // uint256 balance = address(this).balance;
        uint256 available = totalAcceptedBidsInETH - withdrawed;
        require(available > 0, "No balance to withdraw");
        withdrawed += available;
        _withdraw(owner(), available);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "cant withdraw");
    }

    function setReserveState(uint8 state) external onlyOwner {
        reserveState = state;
    }

    function setupTierPrices(
        uint256 t1p,
        uint256 t2p,
        uint256 t3p
    ) external onlyOwner {
        priceT1 = t1p;
        priceT2 = t2p;
        priceT3 = t3p;
    }

    function setTotalAcceptedBidsInETH(uint256 e) external onlyOwner {
        totalAcceptedBidsInETH = e;
    }

    function setCanPublicDeposit(bool b) external onlyOwner {
        canPublicDeposit = b;
    }

    // function getDepositedUsersCount() external view returns (uint256) {
    //     return depositedUsers.length();
    // }

    // function getDepositedUsers(
    //     uint256 fromIdx,
    //     uint256 toIdx
    // ) external view returns (address[] memory) {
    //     toIdx = Math.min(toIdx, depositedUsers.length());
    //     address[] memory part = new address[](toIdx - fromIdx);
    //     for (uint256 i = 0; i < toIdx - fromIdx; i++) {
    //         part[i] = depositedUsers.at(i + fromIdx);
    //     }
    //     return part;
    // }

    function getUserDepositedETHMultiple(
        address[] calldata addresses
    ) external view returns (uint256[] memory) {
        uint256[] memory part = new uint256[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            part[i] = userDepositedETH[addresses[i]];
        }
        return part;
    }
}
