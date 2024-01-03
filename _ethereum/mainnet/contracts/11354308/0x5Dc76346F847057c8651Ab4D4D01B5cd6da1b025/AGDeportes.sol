/*


░█████╗░░██████╗░
██╔══██╗██╔════╝░
███████║██║░░██╗░
██╔══██║██║░░╚██╗
██║░░██║╚██████╔╝
╚═╝░░╚═╝░╚═════╝░

██████╗░███████╗██████╗░░█████╗░██████╗░████████╗███████╗░██████╗
██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██╔════╝
██║░░██║█████╗░░██████╔╝██║░░██║██████╔╝░░░██║░░░█████╗░░╚█████╗░
██║░░██║██╔══╝░░██╔═══╝░██║░░██║██╔══██╗░░░██║░░░██╔══╝░░░╚═══██╗
██████╔╝███████╗██║░░░░░╚█████╔╝██║░░██║░░░██║░░░███████╗██████╔╝
╚═════╝░╚══════╝╚═╝░░░░░░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═════╝░


1.000.000.000 AGD | Sᴘᴏʀᴛ Nᴇᴡs | Sʜᴀʀᴇs

According to its corporate policies, our agency has established the 
integration of these tokens as an element of business interaction in 
relation to profitability and distribution of profits.

These digital assets can be used as commercial exchange elements such
 as promissory notes, shares or any other element indicated by our agency.

The commercial conditions will be determined in the section corresponding
 to the corporate distribution of profits.
 
 
*/



pragma solidity 0.5.11;


contract AGDeportes {
address public ownerWallet;
    string public constant name = "AG DEPORTES";
    string public constant symbol = "AGD";
    uint8 public constant decimals = 18; 

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event TransferFromContract(address indexed from, address indexed to, uint tokens,uint status);

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
   
    uint256 totalSupply_=1000000000000000000000000000;

    using SafeMath for uint256;




   constructor() public { 
       ownerWallet=msg.sender;
        balances[ownerWallet] = totalSupply_;
    } 

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
   
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }
   
    function balanceOfOwner() public view returns (uint) {
        return balances[ownerWallet];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
   
    function transferFromOwner(address receiver, uint numTokens,uint status) internal returns (bool) {
        numTokens=numTokens*1000000000000000000;
        if(numTokens <= balances[ownerWallet]){
        balances[ownerWallet] = balances[ownerWallet].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit TransferFromContract(ownerWallet, receiver, numTokens,status);
        }
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) internal returns (bool) {
        require(numTokens <= balances[owner]);   
        require(numTokens <= allowed[owner][msg.sender]);
   
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}



/*


Learn more about AG Deportes 

AG Deportes©
Website:
 https://agdeportes.com/

 
Social Media:
https://www.facebook.com/agdeportes/
https://twitter.com/AGdeportesNews
https://www.instagram.com/agdeportes

La Pelota Pregunta©
 https://lapelotapregunta.com/


Aᴜᴛʜᴏʀɪᴢᴇᴅ sᴇʟʟᴇʀ ғᴏʀ ᴛʜᴇ sᴀʟᴇ ᴏғ sʜᴀʀᴇs ɪɴ ᴛᴏᴋᴇɴs


░█████╗░██╗░░░░░██╗░░░░░███╗░░░███╗███████╗██████╗░░██████╗░██████╗░░█████╗░██╗░░░██╗██████╗░
██╔══██╗██║░░░░░██║░░░░░████╗░████║██╔════╝██╔══██╗██╔════╝░██╔══██╗██╔══██╗██║░░░██║██╔══██╗
███████║██║░░░░░██║░░░░░██╔████╔██║█████╗░░██║░░██║██║░░██╗░██████╔╝██║░░██║██║░░░██║██████╔╝
██╔══██║██║░░░░░██║░░░░░██║╚██╔╝██║██╔══╝░░██║░░██║██║░░╚██╗██╔══██╗██║░░██║██║░░░██║██╔═══╝░
██║░░██║███████╗███████╗██║░╚═╝░██║███████╗██████╔╝╚██████╔╝██║░░██║╚█████╔╝╚██████╔╝██║░░░░░
╚═╝░░╚═╝╚══════╝╚══════╝╚═╝░░░░░╚═╝╚══════╝╚═════╝░░╚═════╝░╚═╝░░╚═╝░╚════╝░░╚═════╝░╚═╝░░░░░

░█████╗░░█████╗░██████╗░██████╗░░█████╗░██████╗░░█████╗░████████╗██╗░█████╗░███╗░░██╗
██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║
██║░░╚═╝██║░░██║██████╔╝██████╔╝██║░░██║██████╔╝███████║░░░██║░░░██║██║░░██║██╔██╗██║
██║░░██╗██║░░██║██╔══██╗██╔═══╝░██║░░██║██╔══██╗██╔══██║░░░██║░░░██║██║░░██║██║╚████║
╚█████╔╝╚█████╔╝██║░░██║██║░░░░░╚█████╔╝██║░░██║██║░░██║░░░██║░░░██║╚█████╔╝██║░╚███║
░╚════╝░░╚════╝░╚═╝░░╚═╝╚═╝░░░░░░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝


𝐀𝐋𝐋𝐌𝐄𝐃 𝐆𝐑𝐎𝐔𝐏 𝐂𝐎𝐑𝐏𝐎𝐑𝐀𝐓𝐈𝐎𝐍

𝔘𝔫𝔦𝔱𝔢𝔡 𝔖𝔱𝔞𝔱𝔢𝔰 𝔬𝔣 𝔄𝔪𝔢𝔯𝔦𝔠𝔞 (𝚄𝚂𝙰)
𝙵𝚕𝚘𝚛𝚒𝚍𝚊 𝚁𝚎𝚐𝚒𝚜𝚝𝚛𝚊𝚝𝚒𝚘𝚗 𝚠𝚠𝚠.𝚍𝚘𝚜.𝚜𝚝𝚊𝚎.𝚏𝚕.𝚞𝚜 𝚁𝚎𝚐𝚒𝚜𝚝𝚛𝚊𝚝𝚒𝚘𝚗 ℙ𝟙𝟛𝟘𝟘𝟘𝟘𝟟𝟜𝟜𝟙𝟟𝟿 | 𝙵𝚎𝚍𝚎𝚛𝚊𝚕 𝚃𝚊𝚡 𝙸𝚍𝚎𝚗𝚝𝚒𝚏𝚒𝚌𝚊𝚝𝚒𝚘𝚗 𝙽𝚞𝚖𝚋𝚎𝚛 (𝙴𝙸𝙽) 𝟛𝟘-𝟘𝟟𝟡𝟞𝟞𝟜𝟘
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------
-----------------------------------------------
---------------------------------
----------------------
Website:
 https://allmedgroup.org/
 
info@allmedgroup.org

Social Media: 
https://www.facebook.com/allmedgroup/
https://twitter.com/allmedgroup
https://www.instagram.com/allmedgroup/
Telegram: https://t.me/allmedgroup

Aʟʟ Rɪɢʜᴛs Rᴇsᴇʀᴠᴇᴅ. AʟʟᴍᴇᴅGʀᴏᴜᴘ Cᴏʀᴘᴏʀᴀᴛɪᴏɴ

*/