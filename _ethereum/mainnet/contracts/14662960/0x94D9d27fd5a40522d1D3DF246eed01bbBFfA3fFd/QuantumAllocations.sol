//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20.sol";
import "./SafeERC20Upgradeable.sol";
import "./SignatureVerifier_V2.sol";
import "./IERC20Upgradeable.sol";
import "./Strings.sol";

//0x65f89044F80c370D2A56DE50987D81EDa1cca3a8

contract QuantumAllocations is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    SignatureVerifier_V2
{
    using Strings for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC721Upgradeable Quantum;
    IERC20 USDC;
    IERC20 USDT;


    function initialize(address _quantum) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        Quantum = IERC721Upgradeable(_quantum);
        USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    }

    struct projectConfig {
        uint256 maxAllocations;
        uint256 maxAllocationsPerUser;
        uint256 maxAllocationsPerWhale;
        uint256 maxAllocationsPerNonHolder;
        uint256 totalCollected;
        uint256 endDate;
        address signer;
        bool paused;
        bool openForHolders;
        bool openForWhales;
        bool openForPublic;
    }

    mapping(bytes32 => projectConfig) public projectsLedger;
    mapping(bytes32 => mapping(address => uint256)) public investmentPerUser;
    mapping(bytes32 => bool) public projectExist;
    mapping(bytes32 => mapping(uint256 => address)) public tokenLock;

    /* @param projectName : bytes32 representation of the project name
     * @param sig : the signatures generated for the user, including the amount.
     * @param amount : the amount the user want to invest. Need that for accounting
     * and verifying the signature.
     * @param tokenId: the Spectre tokenId. User need to be the owner.
     * will also need it to verify if its a whale token.
     */
    function addInvestmentToProject(
        bytes32 projectName,
        bytes memory sig,
        uint256 amount,
        uint256 tokenId,
        bool tetherOrCoin
    ) external whenNotPaused nonReentrant {
        // checks if the project exist
        require(projectExist[projectName], "No such project");

        if (tokenId <= 2000)
            require(
                projectsLedger[projectName].openForHolders,
                "project not open for non-whales"
            );
        else
            require(
                projectsLedger[projectName].openForWhales,
                "project not open for whales"
            );

        require(
            Quantum.ownerOf(tokenId) == msg.sender,
            "you are not the owner"
        );

        
        if(tokenLock[projectName][tokenId] == address(0))
            tokenLock[projectName][tokenId] = msg.sender;
        else require( tokenLock[projectName][tokenId] == msg.sender, "swiping tokens not allowed!");

        projectConfig memory project = projectsLedger[projectName];

        // checks if deadline is still in the future
        require(project.endDate >= block.timestamp, "project ended");
        // checks if this specific project is not paused.
        require(!project.paused, "project is paused");

        /* verify that this signature was created by the private key
         * that corrosponds to this project's signer address.
         * Also verifies that this signatures was generated for the function caller,
         * and that it includes the EXACT amount they are allowed to invest.
         */
        bool verification = verify(msg.sender, amount, sig, project.signer);
        require(verification, "you are not authorized");

        /* checks that if the user adds in the amount, it will
         * still be greater than or equal to the total allowed allocations
         * for this project.
         */
        require(
            project.totalCollected + amount <= project.maxAllocations,
            "Allocations limit reached"
        );

        /*  check that the amount to invest is still within the limit
            of the user.
        */
        uint256 userInvestment = investmentPerUser[projectName][msg.sender];

        if (tokenId <= 2000)
            require(
                userInvestment + amount <= project.maxAllocationsPerUser,
                "you reached max allocations"
            );
        else
            require(
                userInvestment + amount <= project.maxAllocationsPerWhale,
                "you reached max allocations"
            );

        if (tetherOrCoin)
            USDT.transferFrom(msg.sender, address(this), amount);
        else USDC.transferFrom(msg.sender, address(this), amount);
        // add the amount to the user's portfolio
        investmentPerUser[projectName][msg.sender] += amount;
        // add the amount to the total collected balance by the project.
        projectsLedger[projectName].totalCollected += amount;

        delete project;
        delete userInvestment;
    }


    function addProject(
        bytes32 projectName,
        uint256 _maxAllocations,
        uint256 _maxAllocationsPerUser,
        uint256 _maxAllocationsPerWhale,
        uint256 _maxAllocationsPerNonHolder,
        uint256 _endDate,
        address _signer,
        bool _openForHolders,
        bool _openForWhales,
        bool _openForPublic
    ) external onlyOwner {
        projectsLedger[projectName] = projectConfig({
            maxAllocations: _maxAllocations,
            maxAllocationsPerUser: _maxAllocationsPerUser,
            maxAllocationsPerWhale: _maxAllocationsPerWhale,
            maxAllocationsPerNonHolder: _maxAllocationsPerNonHolder,
            totalCollected: 0,
            endDate: _endDate,
            signer: _signer,
            paused: false,
            openForHolders: _openForHolders,
            openForWhales: _openForWhales,
            openForPublic: _openForPublic
        });

        projectExist[projectName] = true;
    }

    function toggleProjectOpenForHolders(bytes32 projectName)
        external
        onlyOwner
    {
        require(projectExist[projectName], "No such project");
        projectsLedger[projectName].openForHolders = !projectsLedger[
            projectName
        ].openForHolders;
    }

    function toggleProjectOpenForWhales(bytes32 projectName)
        external
        onlyOwner
    {
        require(projectExist[projectName], "No such project");
        projectsLedger[projectName].openForWhales = !projectsLedger[projectName]
            .openForWhales;
    }

    function toggleProjectOpenForPublic(bytes32 projectName)
        external
        onlyOwner
    {
        require(projectExist[projectName], "No such project");
        projectsLedger[projectName].openForPublic = !projectsLedger[projectName]
            .openForPublic;
    }

    function editProjectMaxAllocations(
        bytes32 projectName,
        uint256 _maxAllocations
    ) external onlyOwner {
        require(projectExist[projectName], "No such project");
        projectsLedger[projectName].maxAllocations = _maxAllocations;
    }

    function editProjectMaxAllocationsPerUser(
        bytes32 projectName,
        uint256 _maxAllocationsPerUser
    ) external onlyOwner {
        require(projectExist[projectName], "No such project");
        projectsLedger[projectName]
            .maxAllocationsPerUser = _maxAllocationsPerUser;
    }

    function editMaxAllocationsPerWhale(bytes32 projectName, uint256 _amount)
        external
        onlyOwner
    {
        require(projectExist[projectName], "No such project");
        projectsLedger[projectName].maxAllocationsPerWhale = _amount;
    }

    function editMaxAllocationsPerNonHolder(
        bytes32 projectName,
        uint256 _amount
    ) external onlyOwner {
        require(projectExist[projectName], "No such project");
        projectsLedger[projectName].maxAllocationsPerNonHolder = _amount;
    }

    function editProjectEndDate(bytes32 projectName, uint256 _endDate)
        external
        onlyOwner
    {
        require(projectExist[projectName], "No such project");
        projectsLedger[projectName].endDate = _endDate;
    }

    function editProjectSigner(bytes32 projectName, address _signer)
        external
        onlyOwner
    {
        require(projectExist[projectName], "No such project");
        projectsLedger[projectName].signer = _signer;
    }

    function editProjectPaused(bytes32 projectName, bool _paused)
        external
        onlyOwner
    {
        require(projectExist[projectName], "No such project");
        projectsLedger[projectName].paused = _paused;
    }

    function setQuantumAddress(address _Quantum) external onlyOwner {
        Quantum = IERC721Upgradeable(_Quantum);
    }

    function setUSDC(address _USDC) external onlyOwner {
        USDC = IERC20(_USDC);
    }

    function setUSDT(address _USDT) external onlyOwner {
        USDT = IERC20(_USDT);
    }

    function withdrawUSDC(address _reciever) external onlyOwner {
        uint256 balance = USDC.balanceOf(address(this));
        USDC.transfer(_reciever, balance);
    }

    function withdrawUSDT(address _reciever) external onlyOwner {
        uint256 balance = USDT.balanceOf(address(this));
        USDT.transfer(_reciever, balance);
    }

    function addToInvestmentMapping(bytes32 projectName, address investor, uint256 amount) external onlyOwner{
        require(projectExist[projectName], "No such project");
        investmentPerUser[projectName][investor] += amount;
        projectsLedger[projectName].totalCollected += amount;
    }

    function removeFromInvestmentMapping(bytes32 projectName, address investor, uint256 amount) external onlyOwner{
        require(projectExist[projectName], "No such project");
        investmentPerUser[projectName][investor] -= amount;
        projectsLedger[projectName].totalCollected -= amount;
    }
}
