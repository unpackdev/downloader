// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IStakingRewards {
    function withdrawTorn(uint256 amount) external;
}

interface IRelayerRegistry {
    function getRelayerBalance(address relayer) external returns (uint256);
    function nullifyBalance(address relayer) external;
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract PenalisationProposal {
    address constant _registryAddress = 0x58E8dCC13BE9780fC42E8723D8EaD4CF46943dF2;
    address constant _stakingAddress = 0x5B3f656C80E8ddb9ec01Dd9018815576E9238c29;
	address constant _tornAddress = 0x77777FeDdddFfC19Ff86DB637967013e6C6A116C;

    function getCheatingRelayersBalanceSum(address[15] memory cheatingRelayers) public returns (uint256) {
        uint256 balanceSum;
        for (uint8 i = 0; i < cheatingRelayers.length; i++) {
            balanceSum += IRelayerRegistry(_registryAddress).getRelayerBalance(cheatingRelayers[i]);
        }
        return balanceSum;
    }

    function nullifyRelayersBalance(address[15] memory cheatingRelayers) internal {
        IRelayerRegistry relayerRegistry = IRelayerRegistry(_registryAddress);
        for (uint8 i = 0; i < cheatingRelayers.length; i++) {
            relayerRegistry.nullifyBalance(cheatingRelayers[i]);
        }
    }

    function executeProposal() public {

		// Gas back to developer if executed (15TORN ~ 45$) or lost.
		// Transfer torn from governance to developer.
		IERC20(_tornAddress).transfer(
            0xf3B2e52f2ab3d206975F436EA0AC3856AB3ECDE7,
            15 ether
        );
		
		address[15] memory cheatingRelayers = [
            0x853281B7676DFB66B87e2f26c9cB9D10Ce883F37, // available-reliable-relayer.eth,
            0x0000208a6cC0299dA631C08fE8c2EDe435Ea83B8, // 0xtornadocash.eth,
            0xaaaaD0b504B4CD22348C4Db1071736646Aa314C6, // tornrelayers.eth
            0x36DD7b862746fdD3eDd3577c8411f1B76FDC2Af5, // tornado-crypto-bot-exchange.eth
            0x5007565e69E5c23C278c2e976beff38eF4D27B3d, // official-tornado.eth
            0xa42303EE9B2eC1DB7E2a86Ed6C24AF7E49E9e8B9, // relayer-tornado.eth
            0x18F516dD6D5F46b2875Fd822B994081274be2a8b, // torn69.eth
            0x2ffAc4D796261ba8964d859867592B952b9FC158, // safe-tornado.eth
            0x12D92FeD171F16B3a05ACB1542B40648E7CEd384, // torn-relayers.eth
            0x996ad81FD83eD7A87FD3D03694115dff19db0B3b, // secure-tornado.eth
            0x7853E027F37830790685622cdd8685fF0c8255A2, // tornado-secure.eth
            0xf0D9b969925116074eF43e7887Bcf035Ff1e7B19, // lowfee-relayer.eth
            0xEFa22d23de9f293B11e0c4aC865d7b440647587a, // tornado-relayer.eth
            0x14812AE927e2BA5aA0c0f3C0eA016b3039574242, // pls-im-poor.eth
            0x87BeDf6AD81A2907633Ab68D02c44f0415bc68C1 // tornrelayer.eth
        ];

        uint256 nullifiedTotalAmount = getCheatingRelayersBalanceSum(cheatingRelayers);
        nullifyRelayersBalance(cheatingRelayers);

		// Reuse from proposal #23, let torn back to governance.
		// https://etherscan.io/address/0xccB9a3A5996aD2c11C8831F8cF97f5D8c7E027c6#code
        IStakingRewards(_stakingAddress).withdrawTorn(nullifiedTotalAmount);
    }
}