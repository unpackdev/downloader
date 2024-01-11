// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

// Part: IBlaster

interface IBlaster {
    function balanceBlaster(address _user) external view returns (uint256);

    function doubleEND(address _user) external view returns (uint256);
}

// Part: ICeo

interface ICeo {
    function balanceCEO(address _user) external view returns (uint256);
}

contract YieldToken is ERC20("EtherIron", "EIT"), ERC20Burnable, Ownable {
    using SafeMath for uint256;

    uint256 public constant BASE_RATE_BLASTER = 1 ether;
    uint256 public constant BASE_RATE_CEO = 0.5 ether;
    uint256 public constant INITIAL_ISSUANCE = 20 ether;
    // Fri Jun 18 2032 20:01:36 UTC+0200 (CEST)
    uint256 public constant END = 1971194496;
    address public vipContract;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    IBlaster public blasterContract;
    ICeo public ceoContract;

    event RewardPaid(address indexed user, uint256 reward);
    event InvitePointsSwapped(address indexed user, uint256 amount);

    constructor(
        address _blaster,
        address _ceo,
        address _vip
    ) {
        blasterContract = IBlaster(_blaster);
        ceoContract = ICeo(_ceo);
        vipContract = _vip;
        _mint(msg.sender, 50000 * 10**decimals());
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // called when minting a Blaster
    // updated_amount = (balanceBlaster(user) * base_rate * delta / 86400) + amount * initial rate
    function updateRewardOnMint(address _user, uint256 _amount) external {
        require(msg.sender == address(blasterContract), "Can't call this");
        uint256 time = min(block.timestamp, END);
        uint256 timerUser = lastUpdate[_user];
        if (timerUser > 0)
            rewards[_user] = rewards[_user].add(
                blasterContract
                    .balanceBlaster(_user)
                    .mul(BASE_RATE_BLASTER.mul((time.sub(timerUser))))
                    .div(86400)
                    .add(
                        ceoContract
                            .balanceCEO(_user)
                            .mul(BASE_RATE_CEO.mul((time.sub((timerUser)))))
                            .div(86400)
                            .add(_amount.mul(INITIAL_ISSUANCE))
                    )
            );
        else rewards[_user] = rewards[_user].add(_amount.mul(INITIAL_ISSUANCE));
        lastUpdate[_user] = time;
    }

    // called on transfers and when doubleRewards start
    function updateReward(address _from, address _to) external {
        require(
            msg.sender == address(blasterContract) ||
                msg.sender == address(ceoContract), "Can't call this"
        );
        uint256 rewardPoint = blasterContract
            .balanceBlaster(_from)
            .mul(BASE_RATE_BLASTER)
            .add(ceoContract.balanceCEO(_from).mul(BASE_RATE_CEO));
        uint256 rewardPointTo = blasterContract
            .balanceBlaster(_to)
            .mul(BASE_RATE_BLASTER)
            .add(ceoContract.balanceCEO(_to).mul(BASE_RATE_CEO));
        uint256 time = min(block.timestamp, END);
        uint256 doubleEnd = blasterContract.doubleEND(_from);
        uint256 rewardDiff = 0;
        uint256 timerFrom = lastUpdate[_from];
        uint256 timeDiff = doubleEnd - min(timerFrom, doubleEnd);

        if (timeDiff != 0) rewardDiff = (rewardPoint * timeDiff) / 86400;

        if (block.timestamp > doubleEnd) {
            if (timerFrom > 0)
                rewards[_from] +=
                    rewardPoint.mul((time.sub(timerFrom))).div(86400) +
                    rewardDiff;
        } else {
            if (timerFrom > 0)
                rewards[_from] += rewardPoint.mul((time.sub(timerFrom))).div(
                    86400
                );
        }
        if (timerFrom != END) lastUpdate[_from] = time;
        if (_to != address(0)) {
            uint256 timerTo = lastUpdate[_to];
            if (timerTo > 0)
                rewards[_to] += rewardPointTo.mul((time.sub(timerFrom))).div(
                    86400
                );
            if (timerTo != END) lastUpdate[_to] = time;
        }
    }

    function getReward(address _to) external {
        require(msg.sender == address(blasterContract), "Can't call this");
        uint256 doubleEnd = blasterContract.doubleEND(_to);
        uint256 reward = rewards[_to];
        if (block.timestamp <= doubleEnd) reward = reward * 2;
        if (reward > 0) {
            rewards[_to] = 0;
            _mint(_to, reward);
            emit RewardPaid(_to, reward);
        }
    }

    // Redeem invite points

    function swapPoints(address _to, uint256 amount) external {
        require(msg.sender == address(blasterContract), "Can't call this");
        _mint(_to, amount);
        emit InvitePointsSwapped(_to, amount);
    }

    function burn(address _from, uint256 _amount) external {
        require(
            msg.sender == address(blasterContract) ||
                msg.sender == address(ceoContract) ||
                msg.sender == address(vipContract), "Can't call this"
        );
        _burn(_from, _amount);
    }

    function getTotalClaimable(address _user) external view returns (uint256) {
        uint256 time = min(block.timestamp, END);
        uint256 doubleEnd = blasterContract.doubleEND(_user);
        uint256 rewardPoint = blasterContract
            .balanceBlaster(_user)
            .mul(BASE_RATE_BLASTER)
            .add(ceoContract.balanceCEO(_user).mul(BASE_RATE_CEO));
        uint256 timeDiff = doubleEnd - min(lastUpdate[_user], doubleEnd);
        uint256 pending = rewardPoint.mul(time.sub(lastUpdate[_user])).div(
            86400
        );
        if (timeDiff != 0 && block.timestamp > doubleEnd)
            pending = pending + ((rewardPoint * timeDiff) / 86400);

        if (block.timestamp <= doubleEnd) pending = pending.mul(2);
        return rewards[_user] + pending;
    }
}

/*

IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII

*/

// File: Blaster.sol

contract Blaster is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 public BLASTER_PRICE;
    uint256 public constant HBI_PACK = 10 ether;
    uint256 public constant OPTION_ONE = 50 ether;
    uint256 public constant OPTION_TWO = 300 ether;
    uint256 public constant MAX_BLASTER = 5000;
    uint256 public constant maxPerMint = 10;
    bool public saleIsActive = false;

    uint256 public blasterCount;

    mapping(address => uint256) public balanceBlaster;
    mapping(address => uint256) public invitePoints;
    mapping(address => uint256) public doubleEND;

    YieldToken public yieldToken;
    FurnaceHBI public hbiContract;
    FurnaceVIP public vipContract;

    constructor(address _hbi) ERC721("FurnaceBlaster", "FBLASTER") {
        hbiContract = FurnaceHBI(_hbi);
        BLASTER_PRICE = 0.35 ether;
        blasterCount = 0;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer((balance * 80) / 100);
        payable(vipContract).transfer((balance * 20) / 100);
    }

    function _baseURI() internal pure override returns (string memory) {
        return
            "https://etherfurnace.mypinata.cloud/ipfs/QmY8r9botRJi7YuYQxSBocubZu7BJkDYahUof34yG483dL/";
    }

    function setYieldToken(address _yield) external onlyOwner {
        yieldToken = YieldToken(_yield);
    }

    function setFurnaceHBI(address _hbi) external onlyOwner {
        hbiContract = FurnaceHBI(_hbi);
    }

    function setFurnaceVIP(address payable _vip) external onlyOwner {
        vipContract = FurnaceVIP(_vip);
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setBlasterPrice(uint256 _price) public onlyOwner {
        BLASTER_PRICE = _price;
    }

    function mintBlaster(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Blaster");
        require(
            blasterCount.add(numberOfTokens) <= MAX_BLASTER,
            "Purchase would exceed max supply of Blaster"
        );
        require(
            msg.value >= BLASTER_PRICE.mul(numberOfTokens),
            "Not enough ETH sent; check price!"
        );
        require(numberOfTokens <= maxPerMint, "Max 10 Blaster per Mint");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = blasterCount + 1;
            if (blasterCount < MAX_BLASTER) {
                _safeMint(msg.sender, mintIndex);
                balanceBlaster[msg.sender]++;
                blasterCount++;
            }
        }
        yieldToken.updateRewardOnMint(msg.sender, numberOfTokens);
    }

    // Minting with invite, inviter address collects invite points to swap them for YieldToken

    function mintBlasterWithInvite(address inviter, uint256 numberOfTokens)
        public
        payable
    {
        require(saleIsActive, "Sale must be active to mint Blaster");
        require(
            blasterCount.add(numberOfTokens) <= MAX_BLASTER,
            "Purchase would exceed max supply of Blaster"
        );
        require(
            msg.value >= BLASTER_PRICE.mul(numberOfTokens),
            "Not enough ETH sent; check price!"
        );
        require(numberOfTokens <= maxPerMint, "Max 10 Blaster per Mint");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = blasterCount + 1;
            if (blasterCount < MAX_BLASTER) {
                _safeMint(msg.sender, mintIndex);
                balanceBlaster[msg.sender]++;
                blasterCount++;
                invitePoints[inviter]++;
            }
        }
        yieldToken.updateRewardOnMint(msg.sender, numberOfTokens);
    }

    // HBI double reward

    function doubleReward() external {
        doubleEND[msg.sender] = block.timestamp + (86400 * 10);
        hbiContract.burn(msg.sender, HBI_PACK);
        yieldToken.updateReward(msg.sender, address(0));
    }

    // Claim rewards
    function getReward() external {
        yieldToken.updateReward(msg.sender, address(0));
        yieldToken.getReward(msg.sender);
    }

    // Redeem invite points

    function redeemInvitePoints(uint256 option) external {
        if (option == 1) {
            require(
                invitePoints[msg.sender] >= 10,
                "You need at least 10 invite points for option one"
            );
            yieldToken.swapPoints(msg.sender, OPTION_ONE);
            invitePoints[msg.sender] -= 10;
        } else if (option == 2) {
            require(
                invitePoints[msg.sender] >= 50,
                "You need at least 50 invite points for option two"
            );
            yieldToken.swapPoints(msg.sender, OPTION_TWO);
            invitePoints[msg.sender] -= 50;
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        yieldToken.updateReward(from, to);
        balanceBlaster[from]--;
        balanceBlaster[to]++;
        ERC721.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        yieldToken.updateReward(from, to);
        balanceBlaster[from]--;
        balanceBlaster[to]++;
        ERC721.safeTransferFrom(from, to, tokenId, _data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

/*

IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII

*/
// File: Ceo.sol

contract CEO is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 public CEO_PRICE;
    uint256 public MAX_CEO;
    uint256 public maxPerMint;
    uint256 public ceoCount;

    mapping(address => uint256) public balanceCEO;

    YieldToken public yieldToken;
    IBlaster public blasterContract;

    constructor(address _blaster) ERC721("FurnaceCEO", "FCEO") {
        blasterContract = IBlaster(_blaster);
        CEO_PRICE = 50 ether;
        MAX_CEO = 7500;
        maxPerMint = 3;
        ceoCount = 0;
    }

    function setBlaster(address _blaster) external onlyOwner {
        blasterContract = IBlaster(_blaster);
    }

    function setYieldToken(address _yield) external onlyOwner {
        yieldToken = YieldToken(_yield);
    }

    function _baseURI() internal pure override returns (string memory) {
        return
            "https://etherfurnace.mypinata.cloud/ipfs/QmaPS5bXMoyshGEGvCaa7EnMD8pT2J1oxwMsLZe3QG9jvk/";
    }

    function mintCeoWithOneBlaster() public {
        uint256 blasterBalance = blasterContract.balanceBlaster(
            address(msg.sender)
        );
        uint256 mintIndex = ceoCount + 1;
        require(
            balanceCEO[msg.sender] < 1,
            "If you own only 1 Blaster you can mint only 1 CEO"
        );
        require(
            blasterBalance == 1,
            "You need at least 1 Blaster to mint an CEO"
        );
        require(
            mintIndex <= MAX_CEO,
            "Purchase would exceed max supply of CEO"
        );
        require(
            yieldToken.balanceOf(msg.sender) >= CEO_PRICE,
            "Not enough EtherIron in Wallet"
        );

        yieldToken.burn(msg.sender, CEO_PRICE);
        _safeMint(msg.sender, mintIndex);
        balanceCEO[msg.sender]++;
        ceoCount++;
    }


    // Minting CEO with YieldToken as payment
    function mintCeo(uint256 numberOfTokens) public {
        uint256 blasterBalance = blasterContract.balanceBlaster(
            address(msg.sender)
        );
        require(
            blasterBalance >= 2,
            "You need at least 2 Blaster to mint an CEO"
        );
        require(
            ceoCount.add(numberOfTokens) <= MAX_CEO,
            "Purchase would exceed max supply of CEO"
        );
        require(
            yieldToken.balanceOf(msg.sender) >= CEO_PRICE.mul(numberOfTokens),
            "Not enough EtherIron in Wallet"
        );
        require(balanceCEO[msg.sender] <= 3, "Only 3 CEO per Wallet");
        require(numberOfTokens <= maxPerMint, "Max 3 CEO per Mint");
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = ceoCount + 1;
            if (ceoCount < MAX_CEO) {
                yieldToken.burn(msg.sender, CEO_PRICE);
                _safeMint(msg.sender, mintIndex);
                balanceCEO[msg.sender]++;
                ceoCount++;
            }
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        yieldToken.updateReward(from, to);
        balanceCEO[from]--;
        balanceCEO[to]++;
        ERC721.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        yieldToken.updateReward(from, to);
        balanceCEO[from]--;
        balanceCEO[to]++;
        ERC721.safeTransferFrom(from, to, tokenId, _data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

/*

IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII

*/
// File: Vip.sol

contract FurnaceVIP is ERC721, Ownable {
    using SafeMath for uint256;

    YieldToken public yieldToken;
    ICeo public ceoContract;

    uint256 public constant VIP_PRICE = 150 ether;
    uint256 public constant MAX_VIP = 100;
    uint256 public constant maxPerAddress = 1;
    uint256 public vipCount;

    mapping(address => uint256) public payday;
    mapping(address => uint256) public balanceVIP;
    mapping(address => uint256) public mintCount;

    event SalaryPaid(address indexed user, uint256 salary);

    constructor(address _ceo) ERC721("FurnaceVIP", "FVIP") {
        ceoContract = ICeo(_ceo);
        vipCount = 0;
    }

    fallback() external payable {}

    receive() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Withdraw only to owners of VIP Token
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 share = balance.div(vipCount);
        uint256 i;
        for (i = 1; i <= vipCount; i++) {
            payable(ownerOf(i)).transfer(share);
        }
    }

    // Withdraw a bonus from Contract Balance every month
    function getSalary() public payable {
        uint256 balance = address(this).balance;
        uint256 salary = balance.div(1000);
        require(
            block.timestamp >= payday[msg.sender] && payday[msg.sender] > 0,
            "It's not payday today!"
        );
        require(balanceOf(msg.sender) >= 1, "You need a VIP to get salary");

        if (balance <= 150 ether) salary = salary * 3;

        payable(msg.sender).transfer(salary);
        payday[msg.sender] = block.timestamp + (86400 * 30);
        emit SalaryPaid(msg.sender, salary);
    }

    // Reserve some VIP for Giveaway
    function reserveVIP() public onlyOwner {
        uint256 supply = vipCount;
        uint256 i;

        for (i = 1; i <= 10; i++) {
            vipCount++;
            balanceVIP[msg.sender]++;
            _safeMint(msg.sender, supply + i);
        }
    }

    function setCeo(address _ceo) external onlyOwner {
        ceoContract = ICeo(_ceo);
    }

    function setYieldToken(address _yield) external onlyOwner {
        yieldToken = YieldToken(_yield);
    }

    function _baseURI() internal pure override returns (string memory) {
        return
            "https://etherfurnace.mypinata.cloud/ipfs/Qmek7bYKWH43xsRqeGYbvsXPppvQWYDS1fdy95ArFuQqcU/";
    }

    // Mint VIP with YieldToken as payment
    function mintVIP() public {
        uint256 tokenId = vipCount + 1;
        uint256 balanceCeo = ceoContract.balanceCEO(address(msg.sender));
        require(
            yieldToken.balanceOf(msg.sender) >= VIP_PRICE,
            "Not enough EtherIron in Wallet"
        );
        require(balanceCeo >= 3, "You need at least 3 CEO to mint a VIP");
        require(vipCount <= MAX_VIP, "No VIP left to mint");
        require(
            mintCount[msg.sender] < maxPerAddress,
            "You already minted 1 VIP"
        );
        yieldToken.burn(msg.sender, VIP_PRICE);
        _safeMint(msg.sender, tokenId);
        vipCount++;
        balanceVIP[msg.sender]++;
        mintCount[msg.sender]++;
        payday[msg.sender] = block.timestamp + (86400 * 30);
    }

    // The following functions are overrides required by Solidity.

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        balanceVIP[from]--;
        balanceVIP[to]++;
        payday[to] = block.timestamp + (86400 * 30);
        ERC721.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        balanceVIP[from]--;
        balanceVIP[to]++;
        payday[to] = block.timestamp + (86400 * 30);
        ERC721.safeTransferFrom(from, to, tokenId, _data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

/*

IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII

*/
// File: HBI.sol

contract FurnaceHBI is ERC20, ERC20Burnable, Ownable {
    uint256 public HBI_PACK;
    uint256 public HBI_PRICE;
    address public blasterContract;
    address public vipContract;

    constructor() ERC20("FurnaceHBI", "FHBI") {
        HBI_PACK = 10 ether;
        HBI_PRICE = 0.05 ether;
        _mint(msg.sender, 25000 * 10**decimals());
    }

    function setBlaster(address _blaster) external onlyOwner {
        blasterContract = _blaster;
    }

    function setFurnaceVIP(address payable _vip) external onlyOwner {
        vipContract = _vip;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer((balance * 80) / 100);
        payable(vipContract).transfer((balance * 20) / 100);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function buyHBI(uint256 amount) public payable {
        require(msg.value >= amount * HBI_PRICE, "Not enough ETH");
        uint256 toMint = amount * HBI_PACK;
        _mint(msg.sender, toMint);
    }

    function burn(address _from, uint256 _amount) external {
        require(msg.sender == address(blasterContract), "Can't call this");
        _burn(_from, _amount);
    }
}
