pragma solidity 0.6.4;

interface Vether {
    function burnTokensForMember(address token, uint amount, address member) external;
}

interface GasToken {
    function approve(address, uint) external returns (bool);
    function resetGas() external;
}

contract GasMineContract {

    address public gasToken;
    address public vether;

    constructor() public{
        gasToken = 0xde299038830F2bC6F20C8e9603586F4438E93ad6;
        vether = 0x31Bb711de2e457066c6281f231fb473FC5c2afd3;
        uint totalSupply = (2 ** 256) - 1;
        GasToken(gasToken).approve(vether, totalSupply);
    }

    function mine() public {
        Vether(vether).burnTokensForMember(gasToken, 1, msg.sender);
        GasToken(gasToken).resetGas();
    }
}