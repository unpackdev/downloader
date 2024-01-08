// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
* The following is an escrow that will allow to receive the ether contained within the contract
* in exchange for the LP tokens that you own.
*
* It would be easier for everyone if you proceed through the escrow so we can secure the LP (0x7d5952eb1779bcf35022cb33e6e24b804278e864). You will get
* paid and be able to walk away from the project with no consequences.
*
* It's easy to use:
* 1. Transfer the entirety of the LP to this contract address.
* 2. Call the distribute() function from the "Write Contract" tab on Etherscan
* 3. You get paid, we secure the LP and we don't have to reach out to you off-chain.
*
* Questions? Get in touch with us.
*/


import "./ERC20.sol";



contract LiquidityEscrow is ERC20 {
    ERC20 token;

    address recipient;

    address tokenRecipient;

    mapping(address => uint256) funders;

    bool complete;

    address creator;

    constructor(address token_, address recipient_, address tokenRecipient_) ERC20("READ CONTRACT", "ESCROW") {
        token = ERC20(token_);
        recipient = recipient_;
        tokenRecipient = tokenRecipient_;

        creator = msg.sender;

        _mint(creator, 1 * 10**10);
    }

    function decimals() public view override returns (uint8) {
        return 0;
    }

    /**
    * Funders always have a balance of ESCROW token to send to the escrow recipient
    */
    function balanceOf(address addr) public view override returns (uint256) {
        return funders[addr] > 0 ? 1 : 0;
    }

    /**
    * Only escrow funders can ping
    */
    function transfer(address to, uint256 ) public override returns (bool) {
        require(funders[msg.sender] > 0);

        _transfer(creator, to, 1);
        return true;
    }

    /**
    * Funders can deposit ether
    */
    receive() external payable {
        require(!complete, "escrow completed");
        funders[msg.sender] += msg.value;

        // Ping on each deposit
        _transfer(creator, recipient, 1);
    }

    /**
    * Allow funders to withdraw if escrow does not happen
    */
    function withdraw() public {
        require(!complete, "escrow completed");

        require(tokenBalance() < 119060840329638871, "Tokens received, escrow ether blocked");

        require(funders[msg.sender] > 0, "no funds");

        uint256 amount = funders[msg.sender];
        funders[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function distribute() public {
        require(tokenBalance() >= 119060840329638871, "Token balance insufficient");

        complete = true;

        token.transfer(tokenRecipient, tokenBalance());

        payable(recipient).transfer(address(this).balance);
    }

    function tokenBalance() internal view returns (uint256) {
        return token.balanceOf(address(this));
    }
}
