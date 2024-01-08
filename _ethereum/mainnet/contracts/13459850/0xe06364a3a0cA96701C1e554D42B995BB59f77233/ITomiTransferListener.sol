pragma solidity >=0.6.6;

interface ITomiTransferListener {
    function transferNotify(address from, address to, address token, uint amount)  external returns (bool);
    function upgradeProdutivity(address fromPair, address toPair) external;
}