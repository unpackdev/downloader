/*
 **                                                                                                                                                              
 **                                                                   dddddddd                                                                                   
 **  PPPPPPPPPPPPPPPPP                                                d::::::d                  DDDDDDDDDDDDD                  AAA                 OOOOOOOOO     
 **  P::::::::::::::::P                                               d::::::d                  D::::::::::::DDD              A:::A              OO:::::::::OO   
 **  P::::::PPPPPP:::::P                                              d::::::d                  D:::::::::::::::DD           A:::::A           OO:::::::::::::OO 
 **  PP:::::P     P:::::P                                             d:::::d                   DDD:::::DDDDD:::::D         A:::::::A         O:::::::OOO:::::::O
 **    P::::P     P:::::Paaaaaaaaaaaaa  nnnn  nnnnnnnn        ddddddddd:::::d   aaaaaaaaaaaaa     D:::::D    D:::::D       A:::::::::A        O::::::O   O::::::O
 **    P::::P     P:::::Pa::::::::::::a n:::nn::::::::nn    dd::::::::::::::d   a::::::::::::a    D:::::D     D:::::D     A:::::A:::::A       O:::::O     O:::::O
 **    P::::PPPPPP:::::P aaaaaaaaa:::::an::::::::::::::nn  d::::::::::::::::d   aaaaaaaaa:::::a   D:::::D     D:::::D    A:::::A A:::::A      O:::::O     O:::::O
 **    P:::::::::::::PP           a::::ann:::::::::::::::nd:::::::ddddd:::::d            a::::a   D:::::D     D:::::D   A:::::A   A:::::A     O:::::O     O:::::O
 **    P::::PPPPPPPPP      aaaaaaa:::::a  n:::::nnnn:::::nd::::::d    d:::::d     aaaaaaa:::::a   D:::::D     D:::::D  A:::::A     A:::::A    O:::::O     O:::::O
 **    P::::P            aa::::::::::::a  n::::n    n::::nd:::::d     d:::::d   aa::::::::::::a   D:::::D     D:::::D A:::::AAAAAAAAA:::::A   O:::::O     O:::::O
 **    P::::P           a::::aaaa::::::a  n::::n    n::::nd:::::d     d:::::d  a::::aaaa::::::a   D:::::D     D:::::DA:::::::::::::::::::::A  O:::::O     O:::::O
 **    P::::P          a::::a    a:::::a  n::::n    n::::nd:::::d     d:::::d a::::a    a:::::a   D:::::D    D:::::DA:::::AAAAAAAAAAAAA:::::A O::::::O   O::::::O
 **  PP::::::PP        a::::a    a:::::a  n::::n    n::::nd::::::ddddd::::::dda::::a    a:::::a DDD:::::DDDDD:::::DA:::::A             A:::::AO:::::::OOO:::::::O
 **  P::::::::P        a:::::aaaa::::::a  n::::n    n::::n d:::::::::::::::::da:::::aaaa::::::a D:::::::::::::::DDA:::::A               A:::::AOO:::::::::::::OO 
 **  P::::::::P         a::::::::::aa:::a n::::n    n::::n  d:::::::::ddd::::d a::::::::::aa:::aD::::::::::::DDD A:::::A                 A:::::A OO:::::::::OO   
 **  PPPPPPPPPP          aaaaaaaaaa  aaaa nnnnnn    nnnnnn   ddddddddd   ddddd  aaaaaaaaaa  aaaaDDDDDDDDDDDDD   AAAAAAA                   AAAAAAA  OOOOOOOOO     
 **  
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";

import "./IERC20.sol";
import "./ERC1155.sol";

/**
 * @dev An ERC1155 token for PandaInsight.
 */
contract PandaInsight is ERC1155, Ownable {

    // PAA name
    string public name;
    // PAA symbol
    string public symbol;
    uint256 public constant PaaID = 0;
    uint256 public constant PaaSupply = 10_000;
    mapping(uint256 => uint256) public tokenSupply;
    address public PaaOwner = 0xA62F8ABb12094F5651C8bA7222A0dC1034Ca4B20;

    event WithdrawERC20(address recipient, address tokenAddress, uint256 tokenAmount);
    event WithdrawEther(address recipient, uint256 amount);



    /**
     * @dev Constructor.
     */
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC1155("https://ipfs.io/ipfs/Qmd4mBcg5gD6p1RkSWkpi7gmM58aPx3FcVP7Myq3ykuj8K")
    {
        name = _name;
        symbol = _symbol;
        _mint(PaaOwner, PaaID, PaaSupply, "");
        tokenSupply[PaaID] = PaaSupply;
    }

    /**
     * @dev Returns the total quantity for a token ID
     * @return amount of token in existence
     */
    function totalSupply() public view returns (uint256) {
        return PaaSupply;
    }


    /**
     * @dev withdrawERC20  tokens.
     * @param recipient recipient
     * @param tokenAddress  token
     * @param tokenAmount amount
     */
    function withdrawERC20(
        address recipient,
        address tokenAddress, 
        uint256 tokenAmount
    ) external onlyOwner 
    {
        IERC20(tokenAddress).transfer(recipient, tokenAmount);

        emit WithdrawERC20(recipient, tokenAddress, tokenAmount);
    }

    

    /**
     * @dev withdraw Ether.
     * @param recipient recipient
     * @param amount amount
     */
    function withdrawEther(address payable recipient, uint256 amount) external onlyOwner {
        (bool success,) = recipient.call{value:amount}("");
        require(success, "withdrawEther fail!");
        emit WithdrawEther(recipient, amount);
    }


}
