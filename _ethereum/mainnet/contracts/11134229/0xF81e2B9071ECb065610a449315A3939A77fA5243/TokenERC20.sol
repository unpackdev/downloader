/**
 * caveat! caveat! caveat!
 * After the game is over, RPPG1 tokens will have no value. We will open the next RPPG2 token game as soon as possible according to the rules.
 * The community management will not answer any questions within 1 hour, and we will answer these questions after processing the lock pool transaction.
*/

/**
 * The only community: https://t.me/RankingPrizePoolGame
*/

/**
 * Token game in progress:
 * Token abbreviation: RPPG1
 * Initial number of tokens: 1000
 * Token burning speed: 10%
 * It is recommended to set transaction slippage: 30%? 49.9%
*/

/**
 * Token game rules:
 * 1. We will lock the Uniswap warehouse within 1 hour, and the lock time is 24 hours.
 * 2. After 24 hours, we will cancel the liquidity of the locked position and the game is over.
 * 3. ETH of this token game reward pool = ETH unlocked at the end of the game-ETH initially locked
*/

/**
 * RPPG1 holder ranking reward distribution:
 * 1. Maintain the first place of RPPG1: reward 10% ETH of the bonus pool
 * 2. Maintain the second place of RPPG1: reward 5% ETH of the prize pool
 * 3. Maintain the third place of RPPG1: reward 3% ETH of the bonus pool
 * 4. Keep RPPG1 1-30: 30% of RPPG2 tokens are distributed proportionally
*/

/**
 * RPPG1 (Uniswap) single purchase reward distribution:
 * 1. The first place for one-time purchase of RPPG1: Reward 10% ETH of the total bonus
 * 2. Second place for one-time purchase of RPPG1: Reward 5% ETH of the total bonus.
 * 3. The third place for one-time purchase of RPPG1: Reward 2% ETH of the total bonus
*/

pragma solidity ^0.4.16;
 
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }
 
contract TokenERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;  // 18 是建议的默认值
    uint256 public totalSupply;
 
    mapping (address => uint256) public balanceOf;  //
    mapping (address => mapping (address => uint256)) public allowance;
 
    event Transfer(address indexed from, address indexed to, uint256 value);
 
    event Burn(address indexed from, uint256 value);
 
 
    function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }
 
 
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
 
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
 
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
 
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
 
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
 
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }
 
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
}