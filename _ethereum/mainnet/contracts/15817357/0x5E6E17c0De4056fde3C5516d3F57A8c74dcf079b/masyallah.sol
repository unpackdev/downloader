import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

contract Masyallah is ERC20 {
    constructor() ERC20("Masyallah", "MYSH") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}