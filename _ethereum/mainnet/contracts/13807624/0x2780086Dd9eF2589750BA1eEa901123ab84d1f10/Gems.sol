// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./IBallerBars.sol";
import "./Strings.sol";

contract Gems is ERC721Enumerable, Ownable {

    /**

     _______  ________ __    __      _______   ______  __       __       ________ _______
    |       \|        \  \  |  \    |       \ /      \|  \     |  \     |        \       \
    | ▓▓▓▓▓▓▓\ ▓▓▓▓▓▓▓▓ ▓▓\ | ▓▓    | ▓▓▓▓▓▓▓\  ▓▓▓▓▓▓\ ▓▓     | ▓▓     | ▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓\
    | ▓▓__/ ▓▓ ▓▓__   | ▓▓▓\| ▓▓    | ▓▓__/ ▓▓ ▓▓__| ▓▓ ▓▓     | ▓▓     | ▓▓__   | ▓▓__| ▓▓
    | ▓▓    ▓▓ ▓▓  \  | ▓▓▓▓\ ▓▓    | ▓▓    ▓▓ ▓▓    ▓▓ ▓▓     | ▓▓     | ▓▓  \  | ▓▓    ▓▓
    | ▓▓▓▓▓▓▓\ ▓▓▓▓▓  | ▓▓\▓▓ ▓▓    | ▓▓▓▓▓▓▓\ ▓▓▓▓▓▓▓▓ ▓▓     | ▓▓     | ▓▓▓▓▓  | ▓▓▓▓▓▓▓\
    | ▓▓__/ ▓▓ ▓▓_____| ▓▓ \▓▓▓▓    | ▓▓__/ ▓▓ ▓▓  | ▓▓ ▓▓_____| ▓▓_____| ▓▓_____| ▓▓  | ▓▓
    | ▓▓    ▓▓ ▓▓     \ ▓▓  \▓▓▓    | ▓▓    ▓▓ ▓▓  | ▓▓ ▓▓     \ ▓▓     \ ▓▓     \ ▓▓  | ▓▓
     \▓▓▓▓▓▓▓ \▓▓▓▓▓▓▓▓\▓▓   \▓▓     \▓▓▓▓▓▓▓ \▓▓   \▓▓\▓▓▓▓▓▓▓▓\▓▓▓▓▓▓▓▓\▓▓▓▓▓▓▓▓\▓▓   \▓▓

     _______  ______ _______       ________ __    __ ________
    |       \|      \       \     |        \  \  |  \        \
    | ▓▓▓▓▓▓▓\\▓▓▓▓▓▓ ▓▓▓▓▓▓▓\     \▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓▓▓▓▓▓▓
    | ▓▓  | ▓▓ | ▓▓ | ▓▓  | ▓▓       | ▓▓  | ▓▓__| ▓▓ ▓▓__
    | ▓▓  | ▓▓ | ▓▓ | ▓▓  | ▓▓       | ▓▓  | ▓▓    ▓▓ ▓▓  \
    | ▓▓  | ▓▓ | ▓▓ | ▓▓  | ▓▓       | ▓▓  | ▓▓▓▓▓▓▓▓ ▓▓▓▓▓
    | ▓▓__/ ▓▓_| ▓▓_| ▓▓__/ ▓▓       | ▓▓  | ▓▓  | ▓▓ ▓▓_____
    | ▓▓    ▓▓   ▓▓ \ ▓▓    ▓▓       | ▓▓  | ▓▓  | ▓▓ ▓▓     \
     \▓▓▓▓▓▓▓ \▓▓▓▓▓▓\▓▓▓▓▓▓▓         \▓▓   \▓▓   \▓▓\▓▓▓▓▓▓▓▓

     _______  __        ______   ______  __    __  ______  __    __  ______  ______ __    __
    |       \|  \      /      \ /      \|  \  /  \/      \|  \  |  \/      \|      \  \  |  \
    | ▓▓▓▓▓▓▓\ ▓▓     |  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\ ▓▓ /  ▓▓  ▓▓▓▓▓▓\ ▓▓  | ▓▓  ▓▓▓▓▓▓\\▓▓▓▓▓▓ ▓▓\ | ▓▓
    | ▓▓__/ ▓▓ ▓▓     | ▓▓  | ▓▓ ▓▓   \▓▓ ▓▓/  ▓▓| ▓▓   \▓▓ ▓▓__| ▓▓ ▓▓__| ▓▓ | ▓▓ | ▓▓▓\| ▓▓
    | ▓▓    ▓▓ ▓▓     | ▓▓  | ▓▓ ▓▓     | ▓▓  ▓▓ | ▓▓     | ▓▓    ▓▓ ▓▓    ▓▓ | ▓▓ | ▓▓▓▓\ ▓▓
    | ▓▓▓▓▓▓▓\ ▓▓     | ▓▓  | ▓▓ ▓▓   __| ▓▓▓▓▓\ | ▓▓   __| ▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓ | ▓▓ | ▓▓\▓▓ ▓▓
    | ▓▓__/ ▓▓ ▓▓_____| ▓▓__/ ▓▓ ▓▓__/  \ ▓▓ \▓▓\| ▓▓__/  \ ▓▓  | ▓▓ ▓▓  | ▓▓_| ▓▓_| ▓▓ \▓▓▓▓
    | ▓▓    ▓▓ ▓▓     \\▓▓    ▓▓\▓▓    ▓▓ ▓▓  \▓▓\\▓▓    ▓▓ ▓▓  | ▓▓ ▓▓  | ▓▓   ▓▓ \ ▓▓  \▓▓▓
     \▓▓▓▓▓▓▓ \▓▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓▓ \▓▓   \▓▓ \▓▓▓▓▓▓ \▓▓   \▓▓\▓▓   \▓▓\▓▓▓▓▓▓\▓▓   \▓▓

    **/

    // RGV2YmVycnkjNDAzMCB3YXMgaGVyZQ==

    using Strings for uint256;

    // uint256s
    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public _actualSupply = 0;
    uint256 public _reserveMinted = 0;
    uint256 public currentBallerBarsCost = 35 ether;

    // Addresses
    address _genOneBallerBarsAddress;
    address _genTwoBallerBarsAddress;
    address _ballerChainsAddress;

    bool public _paused = true;

    string private _baseTokenURI = "https://ben-baller-gems-server.herokuapp.com/metadata/";

    constructor() ERC721("Gems", "GEM") {}

    /**
     * @dev Mint reserve. Owner only, for giveaways and tests
     * @param quantity Quantity of tokens
     */

    function mintReserve(uint256 quantity) onlyOwner external  {
        require(_reserveMinted+quantity<6,"EXCEEDS_RESERVE_MINTS");
        _reserveMinted += quantity;
        mintInternal(quantity);
    }

    /**
     * @dev Mint internal, this is to avoid code duplication.
     */

    function mintInternal(uint256 quantity) internal {
        uint256 tokenId = _actualSupply;
        _actualSupply += quantity;
        require(_actualSupply <= MAX_SUPPLY,"EXCEEDS_MAX_SUPPLY");
        require(tx.origin == msg.sender);
        unchecked {
            for (uint256 i = 0; i < quantity; i++) {
                _mint(msg.sender,tokenId);
                tokenId += 1;
            }
        }
    }

    /**
     * @dev Mint for BallerBars
     * @param ballerBarsGeneration The generation of Baller Bars to use.
     * @param quantity The number of tokens to mint
     */

    function mintWithBallerBars(uint256 ballerBarsGeneration, uint256 quantity) public {
        require(_paused==false,"PAUSED");
        IBallerBars ballerBarsContract = getBallerBarsContract(ballerBarsGeneration);
        ballerBarsContract.burnFrom(msg.sender, currentBallerBarsCost * quantity);
        mintInternal(quantity);
    }

    /**
     * @dev Mint for BallerBars with both BallerBars generation one and generation 2
     * @param bbOneAmount The amount of BB generation one to burn
     * @param bbOneAmount The amount of BB generation two to burn
     * @param quantity The number of tokens to mint
     */

    function mintWithBallerBarsSpecial(uint256 bbOneAmount, uint256 bbTwoAmount, uint256 quantity) public {
        require(_paused==false,"PAUSED");
        require(bbOneAmount+bbTwoAmount==currentBallerBarsCost*quantity,"INVALID_COMBINATION");

        IBallerBars ballerBarsGenOneContract = IBallerBars(_genOneBallerBarsAddress);
        IBallerBars ballerBarsGenTwoContract = IBallerBars(_genTwoBallerBarsAddress);

        ballerBarsGenOneContract.burnFrom(msg.sender, bbOneAmount);
        ballerBarsGenTwoContract.burnFrom(msg.sender, bbTwoAmount);

        mintInternal(quantity);
    }

    /**
     * @dev Returns the wallet of a given wallet. Mainly for ease for frontend devs.
     * @param _wallet The wallet to get the tokens of.
     */

    function walletOfOwner(address _wallet)
    public
    view
    returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_wallet);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return tokensId;
    }

    function togglePauseStatus() external onlyOwner {
        _paused = !_paused;
    }

    function setBallerBarsCost(uint256 ballerBarsCost) external onlyOwner {
        currentBallerBarsCost = ballerBarsCost * 1 ether;
    }

    /**
     * @dev Sets BB contract address based on generation
     * @param ballerBarsAddress The BB contract address
     * @param generation The generation of chains contract
     */

    function setBallerBarsAddress(address ballerBarsAddress,uint256 generation) onlyOwner public {
        require(generation==1||generation==2,"INVALID_GEN");
        if(generation == 1){
            _genOneBallerBarsAddress = ballerBarsAddress;
        }else if(generation == 2){
            _genTwoBallerBarsAddress = ballerBarsAddress;
        }
    }

    /**
     * @dev Sets BallerChains contract address
     * @param ballerChainsAddress The BallerChains contract address
     */

    function setBallerChainsAddress(address ballerChainsAddress) onlyOwner public {
        _ballerChainsAddress = ballerChainsAddress;
    }

    /**
     * @dev Returns BB contract based on generation
     * @param generation The generation of contract to return. 1 or 2
     */

    function getBallerBarsContract(uint256 generation) internal view returns (IBallerBars) {
        if(generation == 1){
            return IBallerBars(_genOneBallerBarsAddress);
        }else if(generation == 2){
            return IBallerBars(_genTwoBallerBarsAddress);
        }else{
            revert("INVALID_GEN");
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata newBaseTokenURI) public onlyOwner {
        _baseTokenURI = newBaseTokenURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId),"TOKEN_NOT_MINTED");
        return string(abi.encodePacked(_baseTokenURI,_tokenId.toString()));
    }

    /**
     * @dev Burns Gem
     * @param _tokenId Token Id to Burn
     */

    function burn(uint256 _tokenId) public virtual {
        if (_msgSender() == _ballerChainsAddress) {
            _burn(_tokenId);
        } else {
            require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721Burnable: caller is not owner nor approved");
            _burn(_tokenId);
        }
    }

}
