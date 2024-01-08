// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./provableAPI_0.6.sol";
import "./ILotteryGame.sol";

contract LotteryGameRegulator is
    OwnableUpgradeSafe,
    usingProvable,
    ReentrancyGuardUpgradeSafe
{
    using SafeMath for uint256;
    using Address for address;

    ILotteryGame public lotteryGame;
    IERC20 public lotteryToken;
    string public oracleIpfsHash;
    uint256 public provableGasLimit;
    uint256 public delayForNextCheck;

    bytes32 internal oraclizeCallbackId;

    event newQuerySent(uint256 delay);
    event gameCalled();

    function initialize(address _lotteryGame, address _lotteryToken)
        public
        initializer
    {
        lotteryGame = ILotteryGame(_lotteryGame);
        lotteryToken = IERC20(_lotteryToken);
        provableGasLimit = 600000;
        __ReentrancyGuard_init();
        __Ownable_init();
    }

    receive() external payable {}

    function setOracleIpfsHash(string memory _hash) public onlyOwner {
        oracleIpfsHash = _hash;
    }

    function setProvableGasLimit(uint256 _amount) public onlyOwner {
        provableGasLimit = _amount;
    }

    function setGasPrice(uint256 _gasPrice) public onlyOwner returns (bool) {
        provable_setCustomGasPrice(_gasPrice);
        return true;
    }

    function sendQuery(uint256 _delay) public payable onlyOwner nonReentrant {
        _callProvable_query(_delay);
    }

    function _callProvable_query(uint256 _delay) internal {
        require(
            provable_getPrice("computation", provableGasLimit) <
                address(this).balance,
            "Provable query was NOT sent, please add some ETH to cover for the query fee"
        );

        oraclizeCallbackId = provable_query(
            _delay,
            "computation",
            [oracleIpfsHash, toAsciiString(address(lotteryGame))],
            provableGasLimit
        );
    }

    function __callback(bytes32 _queryId, string memory _result)
        public
        override
    {
        require(
            isProvableCallback(_queryId),
            "Allowed to be invoked only by Provable"
        );
        int256 separatorIndex = indexOf(_result, "|");
        delayForNextCheck = safeParseInt(
            substring(_result, 0, uint256(separatorIndex))
        );
        _result = substring(
            _result,
            uint256(separatorIndex) + 1,
            bytes(_result).length
        );

        separatorIndex = indexOf(_result, "|");

        uint256 gameKeyState =
            safeParseInt(substring(_result, 0, uint256(separatorIndex)));
        _result = substring(
            _result,
            uint256(separatorIndex) + 1,
            bytes(_result).length
        );
        separatorIndex = indexOf(_result, "|");

        uint256 lotteryGameProvableGasLimit =
            safeParseInt(substring(_result, 0, uint256(separatorIndex)));

        uint256 gasPrice =
            safeParseInt(
                substring(
                    _result,
                    uint256(separatorIndex) + 1,
                    bytes(_result).length
                )
            );

        if (gameKeyState == 0) {
            // game was NOT started
            require(
                provable_getPrice("computation", lotteryGameProvableGasLimit) <
                    address(this).balance,
                "Game can't be started because there is not enougth ETH on the contract balance!"
            );
            lotteryGame.startGame{value: address(this).balance}(
                gasPrice,
                lotteryGameProvableGasLimit
            );
            emit gameCalled();
        }
        _callProvable_query(delayForNextCheck);
        emit newQuerySent(delayForNextCheck);
    }

    function emergencyEthWithdraw() public onlyOwner {
        uint256 ethBalance = address(this).balance;
        require(ethBalance != 0, "There is nothing to withdraw");
        (bool success, ) = msg.sender.call{value: ethBalance}("");
        require(success, "Amount was not transfer");
    }

    function withdrawLotto() public onlyOwner {
        uint256 lottoBalance = lotteryToken.balanceOf(address(this));
        require(lottoBalance != 0, "There is nothing to withdraw");
        lotteryToken.transfer(msg.sender, lottoBalance);
    }

    function toAsciiString(address _addr) public pure returns (string memory) {
        bytes memory s = new bytes(42);
        s[0] = "0";
        s[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(_addr) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i + 2] = char(hi);
            s[2 * i + 3] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function isProvableCallback(bytes32 _queryId)
        internal
        virtual
        returns (bool)
    {
        return
            msg.sender == provable_cbAddress() &&
            _queryId == oraclizeCallbackId;
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }
}
