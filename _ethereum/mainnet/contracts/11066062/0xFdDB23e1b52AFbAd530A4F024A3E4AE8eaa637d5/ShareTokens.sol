pragma solidity ^0.6.6;

interface TokenInterface {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract ShareTokens {
    function shareEth(address payable[] memory to, uint256[] memory amounts) payable public {
        uint share_to=to.length;

        require(share_to > 0);
        require(share_to == amounts.length);

        uint256 remainder = msg.value;

        for(uint i=0;i<share_to;i++) {
            to[i].transfer(amounts[i]);
            remainder -= amounts[i];
        }
        msg.sender.transfer(remainder);
    }

    function shareTokens(address tokenContractAddress, address[] memory to, uint256[] memory amounts) public {
        uint share_to = to.length;

        require(share_to > 0);
        require(share_to == amounts.length);

        TokenInterface token = TokenInterface(tokenContractAddress);

        for(uint i=0; i<share_to; i++) {
            token.transferFrom(msg.sender, to[i], amounts[i]);
        }
    }
}