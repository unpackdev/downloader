// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./Billionaire.sol";
import "./Pausable.sol";

contract Golden is Pausable  {

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
    event Withdraw(address _receiver, uint256 _amount);
    event SendToGoldens(address payable _owner, uint256 _amount);
    event ReceiveEther(uint256 _amount);

    constructor() {

    }
    function receiveEher () external payable {
    emit ReceiveEther(msg.value);
  }

    function sendToGoldens(uint256 _amount) external onlyOwner {
        uint256 _totalAmmount = 15 * _amount;
        require(address(this).balance >= _totalAmmount,
            "Billionaire: insufficient contract balance"
        );
        address payable _ownerNFT;
        Billionaire _Billionaire = Billionaire(BillionaireContract);
        for (uint256 ind = 0; ind < 15; ind++) {
            _ownerNFT = payable(_Billionaire.ownerOf(goldenId[ind]));
           _ownerNFT.transfer( _amount);
            emit SendToGoldens(_ownerNFT, _amount);
        }
    }
     function withdraw(uint256 _amount)
        external
        onlyOwner
    {
        require(_amount > 0, "Billionaire: amount is zero");
          require(address(this).balance >= _amount,
            "Billionaire: insufficient contract balance"
        );
         payable (msg.sender).transfer(_amount);
        emit Withdraw(msg.sender, _amount);
    }

}
