// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*                  METACOLLECT             

                            ~??~.                 
                          .G@@@@B:                
                 !PB#G7   ~@@@@@@~   !P##P!       
         ..     ^@@@@@@~  ~@@@@@@~  ^@@@@@@^      
       7B&&BJ   ~@@@@@@!  ~@@@@@@~  ~@@@@@@^      
      ^@@@@@@!  ^@@@@@@!  ~@@@@@@~  ~@@@@@@^      
      ^@@@@@@!  ^@@@@@@!  ~@@@@@@~  ~@@@@@@^      
      ^@@@@@@!  ~@@@@@@!  ~@@@@@@~  ~@@@@@@~      
      ^@@@@@@!  :JJJJJY^  :JJJJJJ:  :JJJJJJ:      
      ^@@@@@@!                                    
      ^@@@@@@!   ~5BBBBBBBBBBBBBBBBBBBBBBBB^      
      ^@@@@@@!  :@@@@@@@@@@@@@@@@@@@@@@@@@@~      
      ^@@@@@@!   J#&@@@@@@@@@@@@@@@@@@@@@@@~      
      :@@@@@@7    .:::::::::::::::::7@@@@@@^      
       B@@@@@P                      5@@@@@#.      
       7@@@@@@Y                    J@@@@@@?       
        Y@@@@@@G~                ^P@@@@@@5        
         ?&@@@@@@G?^.        .^7G@@@@@@@J         
          ^5@@@@@@@@#G5YJJY5G#@@@@@@@@P^          
            ^Y#@@@@@@@@@@@@@@@@@@@@#Y^            
              .~?P#&@@@@@@@@@@&#PJ~.              
                   :^!7????7!^:.                  
*/

import "./ERC20.sol";
import "./ERC20Pausable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract MetaCollect is Ownable, ERC20Pausable {
    event Withdraw(address indexed to, uint256 indexed nonce, uint256 amount);
    event Deposit(address indexed from, uint256 amount);

    address private _signer;
    uint256 private _cap;
    mapping(address => uint256) private _nonces;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _cap = 69e24; //69 million with 18 precision
        _signer = _msgSender();
    }

    function deposit(uint256 amount) public {
        _burn(_msgSender(), amount);
        emit Deposit(_msgSender(), amount);
    }

    function withdraw(address to, uint256 amount, uint256 nonce, uint256 expiry, bytes memory signature) public {
        require(nonce == _nonces[to], "METACOLLECT: Invalid withdrawal nonce");
        require(block.number <= expiry, "METACOLLECT: Expired withdrawal");
        address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(abi.encode(to, amount, nonce, expiry))), signature);
        require(signer == _signer, "METACOLLECT: Invalid withdrawal signature");
        _nonces[to] += 1;
        _mint(to, amount);
        emit Withdraw(to, nonce, amount);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setCap(uint256 newCap) public onlyOwner {
        _cap = newCap;
    }

    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    function setSigner(address signer) public onlyOwner {
        _signer = signer;
    }

    function getSigner() public view returns (address) {
        return _signer;
    }

    function getNonce(address to) public view returns (uint256) {
        return _nonces[to];
    }

    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }
}