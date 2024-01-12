// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./Strings.sol";

///////////////////////////////////////////
/// T-O-S Space Matter                  ///
/// Fashion Wears for the Moonwalkers   ///
/// TOS Dev Team July-2022              ///
//////////////////////////////////////////

contract TOSSpaceMatter is ERC1155, Ownable {

    ///////////////////////////////////////////////////////////
    /// Events - functions to be emitted as events          ///
    ///////////////////////////////////////////////////////////

    event UpdateURI(string indexed _uri);
    event UpdateMinter(address indexed _minter, bool _value);
    event UpdateBurner(address indexed _burner, bool _value);

    ///////////////////////////////////////////////////////////
    /// Conditionals - for the mint and burn functions      ///
    /// Segregated roles for automation                     ///
    ///////////////////////////////////////////////////////////

    modifier onlyMinter() {
        require(minters[msg.sender], 'Only designated minter can mint');
        _;
    }

    modifier onlyBurner() {
        require(burners[msg.sender], 'Only designated burner can burn');
        _;
    }

    ///////////////////////////////////////////////////////////
    /// Public Variables                                    ///
    ///////////////////////////////////////////////////////////

    string public constant name = 'TOS Space Matter';
    string public constant symbol = 'TOSSM';

    mapping(address => bool) public minters;
    mapping(address => bool) public burners;

    string public uri_prefix;
    string private uri_postfix = '.json';

    ///////////////////////////////////////////////////////////
    /// Initialization                                      ///
    ///////////////////////////////////////////////////////////

    constructor(string memory _uri) ERC1155(_uri) {
        _setURI(_uri);
        uri_prefix = _uri;
        emit UpdateURI(_uri);
    }

    ///////////////////////////////////////////////////////////
    /// Key Functions - mint, burn                          ///
    ///////////////////////////////////////////////////////////

    function mint(address[] memory recipients, uint256[] memory ids, uint256[] memory amounts)
        external
        onlyMinter
    {
        uint256 length = recipients.length;
        for (uint256 i; i < length;) {
            _mint(recipients[i], ids[i], amounts[i], '');
            unchecked { ++i; }
        }
    }

    function mintBatch(address[] memory recipients, uint256[][] memory ids, uint256[][] memory amounts)
        external
        onlyMinter
    {
        uint256 length = recipients.length;
        for (uint256 i; i < length;) {
            _mintBatch(recipients[i], ids[i], amounts[i], '');
            unchecked { ++i; }
        }
    }

    function singleMint(address recipient, uint256 id, uint256 amount)
        external
        onlyMinter
    {
        _mint(recipient, id, amount, '');
    }

    function burn(address account, uint256[] memory ids, uint256[] memory amounts)
        external
        onlyBurner
    {
        _burnBatch(account, ids, amounts);
    }

    function burnBatch(address[] memory accounts, uint256[][] memory ids, uint256[][] memory amounts)
        external
        onlyBurner
    {
        uint256 length = accounts.length;
        for (uint256 i; i < length;) {
            _burnBatch(accounts[i], ids[i], amounts[i]);
            unchecked { ++i; }
        }
    }

    ///////////////////////////////////////////////////////////
    /// Key Setters - Getters                               ///
    ///////////////////////////////////////////////////////////

    function updateUri(string memory _newURI) external onlyOwner {
        _setURI(_newURI);
        uri_prefix = _newURI;
        emit UpdateURI(_newURI);
    }

    /// Override the uri in ERC1155 standard function - to allow for varying JSON per token ID
    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(
                uri_prefix,
                Strings.toString(_tokenId),
                uri_postfix
            )
        );
    }

    function addMinter(address _minter) external onlyOwner {
        minters[_minter] = true;
        emit UpdateMinter(_minter, true);
    }

    function removeMinter(address _minter) external onlyOwner {
        minters[_minter] = false;
        emit UpdateMinter(_minter, false);
    }

    function addBurner(address _burner) external onlyOwner {
        burners[_burner] = true;
        emit UpdateBurner(_burner, true);
    }

    function removeBurner(address _burner) external onlyOwner {
        burners[_burner] = false;
        emit UpdateBurner(_burner, false);
    }
}
