//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./IIslandToken.sol";
import "./IStaking.sol";

contract IslandToken is ERC20, ERC20Burnable, Pausable, Ownable, IIslandToken {

    mapping(address => bool) public liquidityPair; // list of liquidity pool's address
    mapping(address => bool) public noFee; // addresses that should not get fees

    uint256[] public taxes; // sales taxes levels
    uint256 public taxToBurn; // waiting tax to be burned

    // staking contract
    IStaking public staking;

    constructor() ERC20("ISLANDS TOKEN", "ISLD") {}

    /*
     * set staking contract
     *
     * @param stakingContract: staking's contract address
     */
    function setStaking(address stakingContract) external onlyOwner {
      staking = IStaking(stakingContract);
    }

    /*
     * set sales taxes
     *
     * @param _newTaxes: amount for each sale tax
     *
     * Error messages:
     *  - I1: "list needs to be 5 element long"
     *  - I2: "tax can not exceed 30%"
     */
    function setTaxes(uint256 a, uint256 b, uint256 c, uint256 d, uint256 e) external onlyOwner {
      require(a <= 30 && b <= 30 && c <= 30 && d <= 30 && d <= 30, "I2");
      taxes = [a, b, c, d, e];
    }

    /*
     * mint
     *
     * @param to: address receiving the minted tokens
     * @param amount: amount received
     *
     * Error messages:
     *  - I3: "Only the staking contract can interract with this function"
     */
    function mint(address to, uint256 amount) external override {
        require(_msgSender() == address(staking), "I3");
        _mint(to, amount);
    }

    /*
     * Before the transfer of any tokens
     *
     * @param from: address sending tokens
     * @param to: address receiving tokens
     * @param amount: amount sent
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    /*
     * override of the basic transfer functino to incorporrate taxes
     *
     * @param from: address sending tokens
     * @param to: address receiving tokens
     * @param amount: amount sent
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 transferAmount = amount;

        if (liquidityPair[to] && !noFee[from])
            transferAmount -= getSellTax(transferAmount);

        uint256 tax = amount - transferAmount;
        if (tax > 0) {
            taxToBurn += tax * 30 / 100;
            super._transfer(from, address(this), tax);
        }

        super._transfer(from, to, transferAmount);
    }

    /*
     * set address as liquidPair
     *
     * @param liquid pair: address of the liquidity pool
     * @param isliq: is a liquidity pool
     */
    function setLiqPair(address liqpair, bool isliq) external onlyOwner {
        liquidityPair[liqpair] = isliq;
    }

    /*
     * set fees to 0 when interracting with set address
     *
     * @param _address: address to have no fees
     * @param noFees: should this address have no fees
     */
    function setNoFee(address _address, bool noFees) external onlyOwner {
        noFee[_address] = noFees;
    }

    function getSellTax(uint256 amount) internal view returns (uint256) {
        uint256 currTax;
        if (amount <= 1000 ether) {
            currTax = taxes[0];
        } else if (amount <= 4000 ether) {
            currTax = taxes[1];
        } else if (amount <= 10000 ether) {
            currTax = taxes[2];
        } else if (amount <= 20000 ether) {
            currTax = taxes[3];
        } else {
            currTax = taxes[4];
        }

        return amount * currTax / 100;
    }

    /*
     * withdraw ERC20 tokens of the contract
     */
    function withdrawProjectIslandTokens() external onlyOwner {
      uint256 totalBalance = balanceOf(address(this)) - taxToBurn;
      taxToBurn = 0;
      _mint(msg.sender, totalBalance);
      _burn(address(this), balanceOf(address(this)));
    }
    /*
     * pause all transfers and mints
     */
    function pause() public onlyOwner {
        _pause();
    }

    /*
     * unpause all transfers and mints
     */
    function unpause() public onlyOwner {
        _unpause();
    }

}
