pragma solidity ^0.8.11;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./IERC20.sol";
import "./IFridge.sol";
import "./IOven.sol";

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@@*   o@#@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@#° °#° #@#@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@#. OO## °#@#@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@###. #@#OO °O#@#@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@° #@##Oo .Oo@##@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@o O@##o#@°.#oo@#@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@### °@#@OO@#° O@Oo@#@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@* ####o@#@°.#o@OO@#@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@### °@##OO@#@°.@Oo#o#@#@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@################@@#@O oO#@o#@#@.°#OooO*###@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@#####@@@@@@@@@@@@@@@@@###* ##OOO@#@# oO#@O#Oo@#@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@###@@@@@#OOoo******ooOO##@@@..##@oo#@@* o#@##o@oO@#@@@@@@@
//@@@@@@@@@@@@@@@@@@@###@@@#Oo*°.................°*O *@@#OOO## °O@##@#o@o##@@@@@@@
//@@@@@@@@@@@@@@@@@##@@@#o°....°°°°°°°°°°°°°°°°°°... .*O@O@#O* o###@#@O##o@#@@@@@@
//@@@@@@@@@@@@@@@##@@#O°...°°°°°°°°°........°°°°°°°° ...°*#@# °O@#@@@##o@o#@#@@@@@
//@@@@@@@@@@@@@@#@@#o...°°°°°°.......°°°°°°°......°. °°°°..*°.oO@#@@@#@OO#o@#@@@@@
//@@@@@@@@@@@@##@#*..°°°°°°...°°*oooooooooooooo**°.  .°°°°°. .oO###@@@#@o#O#@#@@@@
//@@@@@@@@@@@#@@o..°°°°°...°*oooooooooooooooooooooo° . ..°° ...*o###@@#@OO#O@#@@@@
//@@@@@@@@@@#@#°.°°°°°..°*ooooooooooooooooooooooooo° **°..  °°°. *@@#@@@@o#O#@@@@@
//@@@@@@@@##@o..°°°°..°oooooooooooooooooooooooooooo* *oo*. .°°°°°.°#@#@#Oooo#@#@@@
//@@@@@@@#@@* °°°°..°oooooooooooooooooooooooooooooo* *oo° .°..°°°°..O@#o##Ooo@#@@@
//@@@@@@#@#°.°°°°..*oooooooooo*°°°°°*oooooooooooooo* *o* .o**°..°°°..OOO@#O#*##@@@
//@@@@@#@#..°°°. °ooooooooo°..       .*oooooooooooo* *o  ooo°**..°°°° *@#@O#O#@#@@
//@@@@#@#..°°°..*ooooooooo.            .*ooooooooooo °. *ooo*°oo..°°°° o@#OO#O@#@@
//@@@###°.°°°..ooooooooo*.               .oooooooooo.  **ooo***oo° °.°° O@#O#O@#@@
//@@@#@°.°°°..oooooooo*.                   *oooooooo  °o*oo**o**oo° .°°°.##O#O@#@@
//@@#@o °°°..oooooooo.                     oo*****o* .***oo**o**ooo°.°°°..#O#O@#@@
//@### °°°° *oooooooo*.                   .*..... .. *oo**o**oo**oo*..°°° *O#O#@@@
//@#@°.°°° *ooooooooooo.                  ....    . .oooo**°*oo**o*** .°°°.*#O#@@@
//#@o °°°.°ooooooooooooo                ....    .*. °ooooo*°*oo**o***° °°°..@O#@@@
//##..°°°.oooooooooooooo*            ........ .*o* .ooooo*o*°*****°***..°°°.OO#@@@
//@O °°°.°ooooooooooooooo.         ......  ..°ooo. °o******o*********** °°°.°O@#@@
//@°.°°°.oooooooooooooooo.      ......°.   ..°oo* .oo********°***°***°*..°°° o@#@@
//#.°°°.°oooooooooooooooo...........°°   ....°°°.  ..***********°°***°*° °°°.o@#@@
//o.°°° *ooooooooooooooo*........°°°.    °..        .*********°*°****°**..°°.°@#@@
//°.°°..ooooooooooooooo*......°°°°°.     °°        .**********°*°****°**..°°..#@#@
//..°°..ooooooooooooo*°....°°°°°°.      ..**°°.   ..**********°*°***°°**°.°°° O@#@
// °°°.°ooooooooooo*°..°°°°°°..       ....***°.  . .o**********°°***°**°° °°°.o@#@
// °°°.*oooooooooo°...°°°...        .....°****.     *o*********°°***°*°**.°°°.*@#@
//.°°° *oooooooooo****°.    .. ......°.°°**°°°       °o*******°°°**°°°°**..°°.*@#@
//.°°° *ooooooo***ooo*      .°.....°°°°°°***°.       °o*******°°°°*°°°°°°..°°.*@#@
//.°°° *o**********o*..      ....°°°°°°°***°.       °ooo**°°°°°°°°°°°°°°° .°°.*@#@
//.°°°.°o*********o*....     ..°°°°°°°°°*°°.       *o**°......°°°°°°°°°°°.°°°.*@#@
// °°°.°o**********......     .°°°°°°°°°....     .*o°.   . ....°°°°°°°°°°.°°°.o@#@
//.°°°..o*********........      ..°°°°°....     °o*.   ..  .....°°°°°°°°. °°° O@#@
//°.°°..*********.........         ... ....    °o.  .. .    ....°°°°°°°...°°°.#@#@
//o.°°° *******°..........           ...       ..  .        .....°°°°°....°°.°@#@@
//O.°°°.°******°°**.    ...              .       .          ......°°°... °°°.*@#@@
//@°.°°..*********°.      ...           ..                  ......°°.....°°° O@#@@
//@o °°° °********°        ..         ...        .     .   .. ......... °°°.°@#@@@
//##.°°°..********.                   ...        .    ...  . ...........°°° o@#@@@
//#@o °°°..******°                    ..         .           ......... °°°..##@@@@
//###..°°° °*****.                     .          ....      ......... .°°° O@#@@@@
//@#@O °°°..**°°°.                   ..         . .....     ...... . .°°°.°@#@@@@@
//@@#@*.°°°..°°°.                   ....°       . .  ....  ......  ..°°°°.###@@@@@
//@@###..°°°..°°.                  .....°.     . ...   ...  .....   .°°° O@#@@@@@@
//@@@#@#..°°°..°.                  .......         ...... ........  .°° o@#@@@@@@@
//@@@@#@O.°°°°..                   ........         .....  .......  .° *@#@@@@@@@@
//@@@@@#@O..°°°.                    .......  .   .......      ....  . *@#@@@@@@@@@
//@@@@@@#@O..°°.                       .....  ...........     ... .  o@#@@@@@@@@@@
//@@@@@@@#@#...                   .°.   ....  . ....... .     .  .  o@#@@@@@@@@@@@
//@@@@@@@@#@#°                   ...... ..... . .  .... .      ....O@#@@@@@@@@@@@@
//@@@@@@@@@#@o                  .......       ..   ... ..    .°..*#@#@@@@@@@@@@@@@
//@@@@@@@@@@#@o                .......         .        .  ..°.°O@@#@@@@@@@@@@@@@@
//@@@@@@@@@@@#@O               ......          .  . .    .....o@@##@@@@@@@@@@@@@@@
//@@@@@@@@@@@@#@#.             ...             .  .........°o#@##@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@#@#°            .°. .......     .... .   .°O#@@#@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@#@@*            ° .°°°°°°°     ..... .°o#@@@##@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@##@o           . ....°°°.      ... °O@@@##@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@#@O           .o*°°°°°.      .. °#@###@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@#@O          O@@@@@@@O      . °#@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@#@#.       .@#######o       °#@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@#@#.      o@#@@@@#@*      .#@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@#@#°     #@#@@@@#@#      *@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@#@#°   .##@@@@@@#@*     O##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@#@#°  o@#@@@@@@###°   .##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@#@O °@#@@@@@@@@#@#*.*#@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@#@° #@#@@@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@#@O °@#@@@@@@@@@@@##@##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@#@o o##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
contract DogCatcher is Context, IERC20, Ownable {
    /*
        DogCatcher is the first Catcher-type token, designed to condense
        value from disparate liquidity pools. He uses flexible, modular
        strategies optimized for his different targets.
    */
    string private _name = "dog.catcher";
    string private _symbol = "DC";
    uint256 private _totalSupply = 0;
    uint8 private _decimals = 9;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    bool private _active = false;
    IFridge _fridge;
    mapping (address => address) _ovens;
    struct Vest { 
        uint128 vestedTime;
        uint128 ethAmount;
    }
    mapping (address => Vest) private userVests;
    event PresaleVote(uint dcAmount, uint8 indexed vote);
    event UsingFridge(address fridge);
    event AddedTarget(address token, address Oven);
    using SafeMath for uint256;

    function addTarget(address token, address oven) external onlyOwner() {
        // Different ovens are used to "handle" different targets.
        emit AddedTarget(token, oven);
        _ovens[token] = oven;
    }

    function setFavoriteFridge (address fridge) external onlyOwner() {
        // The favorite fridge is used for determining the value 
        // of DC tokens for the minting and vesting steps.
        emit UsingFridge(fridge);
        _fridge = IFridge(fridge);
    }

    function isActive() external view returns (bool) {
        // Inactive during pre-sale period.
        return _active;
    }

    function presaleMint(uint8 vote) public payable returns (uint256) {
        // Pre-sale open to public at 1m DC per ETH. This provides the initial
        // LP and pays our wonderful artist & front-end dev.
        require(!_active, "Presale is over!");
        uint256 mintedAmount = msg.value / 1000; 
        _mint(_msgSender(), mintedAmount);
        emit PresaleVote(mintedAmount, vote);
        return mintedAmount;
    }

    function endPresale () public onlyOwner() {
        require(!_active, "Already active.");
        // Pre-sold tokens represent 50% of the supply. The other 50% are minted 
        // and sent along with ETH to be added to LP manually.
        _mint(_msgSender(), _totalSupply);
        payable(owner()).transfer(address(this).balance);
        _active = true;
    }

    function otcOffer(address token, uint256 amount) public view returns (uint256 ethValue, uint256 paperValue, uint256 vestedTime) {
        // DC consults the proper oven and gives the users some choices
        // for how to dispose of their tokens.
        require(_ovens[token] != address(0), "Token not targeted.");
        (ethValue, paperValue, vestedTime) = IOven(_ovens[token]).otcOffer(token, amount);
    }

    function instaMint(address token, uint256 incomingTokenAmount) public {
        // User can instantly mint at a value comparable to what they would get
        // selling on the open market.
        require(_ovens[token] != address(0), "Token not targeted.");
        IOven oven = IOven(_ovens[token]);
        oven.updatePrice(token);
        IERC20(token).transferFrom(_msgSender(), address(oven), incomingTokenAmount);
        (uint256 ethValueIncoming, ) = oven.getValues(token, incomingTokenAmount);
        _fridge.updatePrice();
        _mint(_msgSender(), _fridge.valuate(ethValueIncoming));
    }

    function vestMint(address token, uint256 amount) public {
        // User mints a higher value, (not subject to price impact), in
        // a vesting position denominated in ETH.
        require(_ovens[token] != address(0), "Token not targeted.");
        IOven oven = IOven(_ovens[token]);
        oven.updatePrice(token);
        IERC20(token).transferFrom(_msgSender(), address(oven), amount);
        (, uint256 paperValue, uint256 vestedTime) = oven.otcOffer(token, amount);
        _vest(_msgSender(), vestedTime, paperValue);
    }   

    function _vest(address user, uint256 time, uint256 ethAmount) private {
        // Handles adding to existing vest: Maximum of timestamps, sum of values.
        Vest storage currentVest = userVests[user];
        uint128 time128 = uint128(time);
        uint128 newEthAmount = currentVest.ethAmount + uint128(ethAmount);
        uint128 newTime = time128 > currentVest.vestedTime ? time128 : currentVest.vestedTime;
        currentVest.vestedTime = newTime;
        currentVest.ethAmount = newEthAmount;
    }

    function vestOf(address user) public view returns (Vest memory) {
        return userVests[user];
    }

    function completeVest() public {
        // Finalizes vests that are past the completion date.
        // DC are issued at DC/ETH rate at time of completion.
        Vest storage userVest = userVests[_msgSender()];
        require(userVest.vestedTime < block.timestamp, "Your dogs are still cookin'.");
        _fridge.updatePrice();
        _mint(_msgSender(), _fridge.valuate(userVest.ethAmount));
        userVests[_msgSender()] = Vest(0, 0);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(_active, "Can't transfer during presale.");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    //Fail-safe functions for releasing tokens, not meant to be used.
    function release(address token) public {
        IERC20(token).transfer(owner(), 
            IERC20(token).balanceOf(address(this)));
    }

    //The rest is all boilerplate ERC-20, but go ahead and read if you need a sleeping aid.
    function name() public view returns (string memory) {return _name;}
    function symbol() public view returns (string memory) {return _symbol;}
    function decimals() public view returns (uint8) {return _decimals;}
    function totalSupply() public view override returns (uint256) {return _totalSupply;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }
}
