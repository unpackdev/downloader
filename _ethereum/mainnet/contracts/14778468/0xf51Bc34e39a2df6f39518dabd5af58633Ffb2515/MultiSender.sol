//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "./Storage.sol";
import "./IERC20.sol";
import "./Ownable.sol";

struct ProductItem {
    bytes32 i18nId;
    bytes32 appId;
    uint256 price;
    uint128 payType;
    uint128 off;
    uint256 duration;
    uint256 createdAt;
    address createdBy;
    address updatedBy;
}

struct VIPStats {
    uint256 startedAt;
    uint256 expiredAt;
}

interface IFinance {
    function queryProduct(bytes32 id) external returns (ProductItem memory);

    function checkout(
        bytes32 orderid,
        address payer,
        bytes32 skuId,
        address inviter
    ) external payable;
}

interface IVIP {
    function queryVIP(bytes32 appId, address target)
        external
        view
        returns (VIPStats memory vipStats);
}

contract MultiSender is Ownable {
    event MultisendTokenOK(address indexed _from, address indexed token);
    event WithdrawSuccessed(address indexed _from);
    event WithdrawERC20Successed(address indexed _from, address indexed token);

    address public checkoutContract;
    address public vipContract;

    function setCheckoutContract(address _checkout) public onlyOwner {
        checkoutContract = _checkout;
    }

    function setVipContract(address _vip) public onlyOwner {
        vipContract = _vip;
    }

    constructor(address _checkout, address _vip) {
        checkoutContract = _checkout;
        vipContract = _vip;
    }

    function multisendToken(
        address token,
        address[] memory _contributors,
        uint256[] memory _balances,
        address inviter,
        bytes32 orderid,
        bytes32 appId
    ) public payable {
        //solhint-disable reason-string
        require(
            _contributors.length <= 100,
            "MultiSenderV1: _contributors length must be less than or equal to 100"
        );
        //solhint-disable reason-string
        require(
            _contributors.length == _balances.length,
            "MultiSenderV1: _contributors length and _balances length must be the same"
        );

        uint256 total = 0;
        for (uint256 i = 0; i < _balances.length; i++) {
            total = total + _balances[i];
        }
        uint256 minMainCoin = total;

        if (address(0) != token) {
            minMainCoin = 0;
        }
        IVIP vip = IVIP(vipContract);

        VIPStats memory vipInfo = vip.queryVIP(appId, msg.sender);
        // solhint-disable not-rely-on-time
        if (vipInfo.expiredAt < block.timestamp) {
            // Non-VIP need to pay
            IFinance finance = IFinance(checkoutContract);
            bytes32 skuId = querySkuId(_contributors.length);

            require(
                msg.value > minMainCoin,
                "MultiSenderV1: msg.value should greater than the amount of tokens"
            );

            // Main Coin multisend: Pay the software fee, msg.value minus the number of tokens to be sent
            // ERC20 token multisend: Pay the software fee
            // uint256 v = uint256(msg.value) - minMainCoin;
            uint256 v = msg.value - minMainCoin;

            finance.checkout{value: v * 1 wei}(
                orderid,
                msg.sender,
                skuId,
                inviter
            );
        } else {
            //   VIP send for free
            if (address(0) == token) {
                require(
                    msg.value == total,
                    "MultiSenderV1: msg.value should be equal to the amount of tokens you want to send without paying software fees"
                );
            } else {
                require(msg.value == 0, "MultiSenderV1: msg.value should be 0");
            }
        }

        if (address(0) == token) {
            //solhint-disable reason-string
            require(
                msg.value >= total,
                "MultiSenderV1: insufficient MainCoin balance"
            );
            // Main Coin multisend
            executeNativeTokenTransfer(_contributors, _balances);
        } else {
            IERC20 eRC20Token = IERC20(token);
            require(
                eRC20Token.balanceOf(msg.sender) >= total,
                "MultiSenderV1: insufficient ERC20Coin balance"
            );
            //solhint-disable reason-string
            require(
                eRC20Token.allowance(msg.sender, address(this)) >= total,
                "MultiSenderV1: insufficient allowance"
            );
            // ERC20 token multisend
            executeERC20Transfer(eRC20Token, _contributors, _balances);
        }

        //  event MultisendTokenOK
        emit MultisendTokenOK(msg.sender, token);
    }

    function executeNativeTokenTransfer(
        address[] memory receivers,
        uint256[] memory _balances
    ) internal {
        for (uint256 i = 0; i < receivers.length; i++) {
            address payable recipient = payable(address(receivers[i]));
            // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
            (bool success, ) = recipient.call{value: _balances[i]}(
                "0x506f7765726564206279206269756269752e746f6f6c73000000000000000000"
            );
            require(
                success,
                "Address: unable to send value, recipient may have reverted"
            );
        }
    }

    function executeERC20Transfer(
        IERC20 eRC20Token,
        address[] memory receivers,
        uint256[] memory _balances
    ) internal {
        for (uint256 i = 0; i < receivers.length; i++) {
            eRC20Token.transferFrom(msg.sender, receivers[i], _balances[i]);
        }
    }

    function querySkuId(uint256 len) public pure returns (bytes32 skuId) {
        if (len <= 20) {
            return
                0x6d756c746973656e6465722d6e6f746f76657232302d7070702d306400000000;
        } else {
            return
                0x6d756c746973656e6465722d6f76657232302d7070702d306400000000000000;
        }
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Finance: insufficient balance");
        address payable recipient = payable(address(owner()));
        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: address(this).balance}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );

        emit WithdrawSuccessed(address(owner()));
    }

    function withdrawERC20(address token) public onlyOwner {
        IERC20 erc20Token = IERC20(token);
        require(
            erc20Token.balanceOf(address(this)) > 0,
            "Address: insufficient balance"
        );
        erc20Token.transfer(
            address(owner()),
            erc20Token.balanceOf(address(this))
        );
        emit WithdrawERC20Successed(address(owner()), token);
    }
}
