// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./IERC20.sol";
import "./Billionaire.sol";
import "./Pausable.sol";

contract Golden is Pausable {
    uint256[15] private goldenId = [
        143,
        311,
        723,
        1304,
        1894,
        2349,
        3421,
        3874,
        4068,
        5226,
        5841,
        6410,
        8476,
        8888,
        9998
    ];

    address payable public constant BillionaireContract =
        payable(0x5DF340b5D1618c543aC81837dA1C2d2B17b3B5d8);
    address token;
    event ChangeToken(address indexed _token);
    event SendToken(address indexed _token, uint256 _amount);
    event WithdrawToken(address indexed _receiver, address indexed _token);
    event SendToGoldens(address indexed _owner, uint256 _amount);

    constructor(address _token) {
        token = _token;
    }

    function setTokenAddress(address _token) external onlyOwner {
        token = _token;
        emit ChangeToken(_token);
    }

    function sendToken(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Billionaire: amount is zero.");
        IERC20(token).transferFrom(msg.sender, address(this), _amount);
        emit SendToken(token, _amount);
    }

    function withdrawToken(uint256 _amount, address _receiver)
        external
        onlyOwner
    {
        require(_amount > 0, "Billionaire: amount is zero");
        require(_receiver != address(0), "Billionaire: address is zero");
        IERC20(token).transfer(_receiver, _amount);
        emit WithdrawToken(_receiver, token);
    }

    function sendToGoldens(uint256 _amount) external onlyOwner {
        uint256 _totalAmmount = 15 * _amount;
        require(
            IERC20(token).balanceOf(address(this)) >= _totalAmmount,
            "Billionaire: insufficient balance"
        );
        address _ownerNFT;
        Billionaire _Billionaire = Billionaire(BillionaireContract);
        for (uint256 ind = 0; ind < 15; ind++) {
            _ownerNFT = _Billionaire.ownerOf(goldenId[ind]);
            IERC20(token).transfer(_ownerNFT, _amount);
            emit SendToGoldens(_ownerNFT, _amount);
        }
    }
}
