// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC165Checker.sol";
import "./Initializable.sol";
import "./IRoboFiERC20.sol";
import "./Ownable.sol";
import "./IConfigurator.sol";
import "./Errors.sol";

import "./DABotCommon.sol"; 
import "./IDABotManager.sol"; 
import "./IDABot.sol"; 
import "./IBotVault.sol";
import "./BotRepository.sol"; 

contract DABotManager is Context, Ownable, Initializable, IDABotManagerEvent {

    using BotRepositoryLib for BotRepository;
    using ERC165Checker for address;

    BotRepository private botRepo;
    BotRepository private templateRepo;
    
    IConfigurator internal _configurator;
    IBotVaultManager public immutable vaultManager;

    modifier supportIDABot(address account) {
        require(account.supportsInterface(type(IDABot).interfaceId), Errors.BM_DOES_NOT_SUPPORT_IDABOT);
        _;
    }

    constructor(IBotVaultManager vault) {
        vaultManager = vault;
    }

    function initialize(IConfigurator configuratorProvider) external payable initializer {
        _transferOwnership(_msgSender());
        _configurator = configuratorProvider;
        
    }

    function setConfigurator(IConfigurator provider) external onlyOwner {
        _configurator = provider;
    }

    function configurator() external view returns(IConfigurator) {
        return _configurator;
    }
   
    function totalBots() external view returns(uint) {
        return botRepo.bots.length;
    }

    /**
    @dev Registers a DABot template (i.e., master contract). 
    Registered template cannot be removed.
     */
    function addTemplate(address template) public supportIDABot(template) onlyOwner {
        templateRepo.addBot(IDABot(template));
        BotMetaData memory metadata = IDABot(template).metadata();

        emit TemplateRegistered(template, metadata.name, metadata.version, metadata.botType); 
    }

    /**
    @dev Retrieves a list of registered DABot templates.
     */
    function templates() external view returns(IDABot[] memory) {
        return templateRepo.bots;
    }

    /**
    @dev Determine whether an address is a registered bot template.
     */
    function isRegisteredTemplate(address template) external view returns(bool) {
        return templateRepo.indexOf(template) > 0;
    } 

    function isRegisteredBot(address account) public view returns(bool) {
        return botRepo.indexOf(account) > 0;
    }

    function removeBots(address[] calldata bots) external onlyOwner {
        for(uint i = 0; i < bots.length; i ++) {
            botRepo.removeBot(IDABot(bots[i]));
            emit BotRemoved(bots[i]);
        }
    }


    /**
    @dev Deploys a bot for a given template.

    params:
        `template`  : address of the master contract containing the logic of the bot
        `name`      : name of the bot
        `setting`   : various settings of the bot. See {sol\DABot.BotSetting}
     */
    function deployBot(address template, 
                        string calldata symbol, 
                        string calldata name,
                        BotModuleInitData[] calldata initData
                        ) external returns(uint botId, address bot) {

        string memory qualifiedName = string(abi.encodePacked(symbol, ":", name)); 

        require(botRepo.indexOfQFN(qualifiedName) == 0, Errors.BM_DUPLICATED_BOT_QUALIFIED_NAME);
        require(templateRepo.indexOf(template) > 0, Errors.BM_TEMPLATE_IS_NOT_REGISTERED);

        IRoboFiFactory factory = IRoboFiFactory(_configurator.addressOf(AddressBook.ADDR_FACTORY));
        IRoboFiERC20 vics = IRoboFiERC20(_configurator.addressOf(AddressBook.ADDR_VICS));

        require(address(factory) != address(0), Errors.CM_FACTORY_ADDRESS_IS_NOT_CONFIGURED);
        require(address(vics) != address(0), Errors.CM_VICS_ADDRESS_IS_NOT_CONFIGURED);

        BotMetaData memory meta = BotMetaData(name, symbol, '', 0, false, false, false, 
            _msgSender(), address(this), template, address(0));

        bot = factory.deploy(template, abi.encode(meta, initData), true);

        IDABot daBot = IDABot(bot);

        BotSetting memory setting = daBot.setting();
        meta = daBot.metadata();

        require(meta.gToken != address(0), Errors.BM_GOVERNANCE_TOKEN_IS_NOT_DEPLOYED);

        vics.transferFrom(_msgSender(), meta.gToken, setting.initDeposit); 
        botRepo.addBot(daBot);
        daBot.createPortfolioVaults();
        daBot.createGovernVaults();

        emit BotDeployed(botId, bot, daBot.botDetails());
    }

    /**
    @dev Gets the bot id for the specified bot name. Returns -1 if no bot found.
     */
    function botIdOf(string calldata qualifiedName) external view returns(int) {
        return int(botRepo.indexOfQFN(qualifiedName)) - 1; 
    }
    
    /**
    @dev Queries details information for a list of bot Id.
     */
    function queryBots(uint[] calldata botId) external view returns(BotDetail[] memory output) {
        output = new BotDetail[](botId.length);
        for(uint i = 0; i < botId.length; i++) {
            if (botId[i] >= botRepo.bots.length) continue;
            IDABot bot = botRepo.bots[botId[i]];
            output[i] = bot.botDetails();
            output[i].id = botId[i];
        }
    }

    function snapshot(address botAccount) external {
        require(isRegisteredBot(botAccount), Errors.BM_BOT_IS_NOT_REGISTERED);
        IDABot(botAccount).snapshot();
    }
}

