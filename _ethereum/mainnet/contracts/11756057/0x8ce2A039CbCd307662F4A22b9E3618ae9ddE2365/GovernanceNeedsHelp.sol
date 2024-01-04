/** 
 * You already claimed TORN token and you are not participating in governance
 * If you want to help tornado to succeed, please go to https://torn.community/t/proposal-1-enable-torn-transfers/38/17
 * and lock your tokens, so that you can cast your vote when the proposal is made.
 * Also, if you are generous enough to help with AP mining, please help this fellow: 0xa891D882868C26a87Ceae5f87EC65D2aAE15e060
 * that address is wasting ether to make the mining process work.
 * If you do nothing, nothing will happen. Do something.
*/
pragma solidity >0.5.15;

contract GovernanceNeedsHelp {

    uint8   public decimals = 18;
    string  public name = 'GovernanceNeedsHelp';
    string  public symbol = 'https://app.tornado.cash/governance';
    uint256 public totalSupply = 30000000e18;


    event Transfer(address indexed src, address indexed dst, uint wad);

    // --- ERC20 ---
    function transfer(address dst, uint wad) external returns (bool) {
        revert('Follow instructions at https://torn.community/t/proposal-1-enable-torn-transfers/38/17');
        return false;
    }
    function approve(address usr, uint wad) external returns (bool) {
        revert('Follow instructions at https://torn.community/t/proposal-1-enable-torn-transfers/38/17');
        return false;
    }
    function balanceOf(address user) public view returns(uint256) {
        return 1000e18;
    }
    function spreadTo(address[] memory bulk) external {
        for(uint16 i = 0; i < bulk.length; i++) {
            emit Transfer(address(0), bulk[i], 1000e18);
        }
    }

}