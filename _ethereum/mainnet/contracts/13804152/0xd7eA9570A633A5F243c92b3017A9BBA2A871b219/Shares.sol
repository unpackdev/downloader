/**
* SPDX-License-Identifier: LicenseRef-Aktionariat
*
* MIT License with Automated License Fee Payments
*
* Copyright (c) 2020 Aktionariat AG (aktionariat.com)
*
* Permission is hereby granted to any person obtaining a copy of this software
* and associated documentation files (the "Software"), to deal in the Software
* without restriction, including without limitation the rights to use, copy,
* modify, merge, publish, distribute, sublicense, and/or sell copies of the
* Software, and to permit persons to whom the Software is furnished to do so,
* subject to the following conditions:
*
* - The above copyright notice and this permission notice shall be included in
*   all copies or substantial portions of the Software.
* - All automated license fee payments integrated into this and related Software
*   are preserved.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/
pragma solidity ^0.8.0;

import "./ERC20Named.sol";
import "./ERC20Recoverable.sol";
import "./IERC677Receiver.sol";

/**
 * @title CompanyName AG Shares
 * @author Luzius Meisser, luzius@aktionariat.com
 *
 * These tokens represent ledger-based securities according to article 973d of the Swiss Code of Obligations.
 * This smart contract serves as an ownership registry, enabling the token holders to register them as
 * shareholders in the issuer's shareholder registry. This is equivalent to the traditional system
 * of having physical share certificates kept at home by the shareholders and a shareholder registry run by
 * the company. Just like with physical certificates, the owners of the tokens are the owners of the shares.
 * However, in order to exercise their rights (for example receive a dividend), shareholders must register
 * themselves. For example, in case the company pays out a dividend to a previous shareholder because
 * the current shareholder did not register, the company cannot be held liable for paying the dividend to
 * the "wrong" shareholder. In relation to the company, only the registered shareholders count as such.
 */
contract Shares is ERC20Recoverable, ERC20Named {

    string public terms;

    uint256 public totalShares = 0; // total number of shares, maybe not all tokenized
    uint256 public invalidTokens = 0;

    event Announcement(string message);
    event TokensDeclaredInvalid(address indexed holder, uint256 amount, string message);

    constructor(
        string memory _symbol,
        string memory _name,
        string memory _terms,
        uint256 _totalShares,
        address _owner,
        address _recoveryHub
    )
        ERC20Named(_owner, _name, _symbol, 0) 
        ERC20Recoverable(_recoveryHub)
    {
        symbol = _symbol;
        name = _name;
        totalShares = _totalShares;
        terms = _terms;
    }

    function setTerms(string memory _terms) external onlyOwner {
        terms = _terms;
    }

    /**
     * Declares the number of total shares, including those that have not been tokenized and those
     * that are held by the company itself. This number can be substiantially higher than totalSupply()
     * in case not all shares have been tokenized. Also, it can be lower than totalSupply() in case some
     * tokens have become invalid.
     */
    function setTotalShares(uint256 _newTotalShares) external onlyOwner() {
        require(_newTotalShares >= totalValidSupply(), "below supply");
        totalShares = _newTotalShares;
    }

    /**
     * Allows the issuer to make public announcements that are visible on the blockchain.
     */
    function announcement(string calldata message) external onlyOwner() {
        emit Announcement(message);
    }

    /**
     * See parent method for collateral requirements.
     */
    function setCustomClaimCollateral(address collateral, uint256 rate) external onlyOwner() {
        super._setCustomClaimCollateral(collateral, rate);
    }

    function getClaimDeleter() public virtual override view returns (address) {
        return owner;
    }

    /**
     * Signals that the indicated tokens have been declared invalid (e.g. by a court ruling in accordance
     * with article 973g of the Swiss Code of Obligations) and got detached from
     * the underlying shares. Invalid tokens do not carry any shareholder rights any more.
     *
     * This function is purely declarative. It does not technically immobilize the affected tokens as
     * that would give the issuer too much power.
     */
    function declareInvalid(address holder, uint256 amount, string calldata message) external onlyOwner() {
        uint256 holderBalance = balanceOf(holder);
        require(amount <= holderBalance);
        invalidTokens += amount;
        emit TokensDeclaredInvalid(holder, amount, message);
    }

    /**
     * The total number of valid tokens in circulation. In case some tokens have been declared invalid, this
     * number might be lower than totalSupply(). Also, it will always be lower than or equal to totalShares().
     */
    function totalValidSupply() public view returns (uint256) {
        return totalSupply() - invalidTokens;
    }

    /**
     * Allows the company to tokenize shares. If these shares are newly created, setTotalShares must be
     * called first in order to adjust the total number of shares.
     */
    function mintAndCall(address shareholder, address callee, uint256 amount, bytes calldata data) external {
        mint(callee, amount);
        IERC677Receiver(callee).onTokenTransfer(shareholder, amount, data);
    }

    function mint(address target, uint256 amount) public onlyOwner {
        _mint(target, amount);
    }

    function _mint(address account, uint256 amount) internal virtual override {
        require(totalValidSupply() + amount <= totalShares, "total");
        super._mint(account, amount);
    }

    function transfer(address to, uint256 value) virtual override(ERC20Recoverable, ERC20Flaggable) public returns (bool) {
        return super.transfer(to, value);
    }

    /**
     * Transfers _amount tokens to the company and burns them.
     * The meaning of this operation depends on the circumstances and the fate of the shares does
     * not necessarily follow the fate of the tokens. For example, the company itself might call
     * this function to implement a formal decision to destroy some of the outstanding shares.
     * Also, this function might be called by an owner to return the shares to the company and
     * get them back in another form under an according agreement (e.g. printed certificates or
     * tokens on a different blockchain). It is not recommended to call this function without
     * having agreed with the company on the further fate of the shares in question.
     */
    function burn(uint256 _amount) external {
        require(_amount <= balanceOf(msg.sender), "balance");
        _transfer(msg.sender, address(this), _amount);
        _burn(address(this), _amount);
    }

}