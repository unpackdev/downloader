// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

import "./Strings.sol";
import "./OwnableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./IHandler.sol";
import "./Structs.sol";
import "./Base64.sol";
import "./Memory.sol";

contract ERC721Base is ERC721EnumerableUpgradeable, OwnableUpgradeable {

	using CountersUpgradeable for CountersUpgradeable.Counter;
	CountersUpgradeable.Counter private _tokenIds;

	uint256 public price;
	mapping(address => uint256) public discounts;
	uint256 public maxMint;
	uint256 public maxTotal;

	bool public paused;
	IHandler public handler;
	mapping (uint256 => uint256) public seeds;

	string[] public scripts;
	string[] public fyrdScripts;
	string[] public externalScripts;

	bool allowCustom;
	mapping (uint256 => string[]) public c_scripts;
	mapping (uint256 => string[]) public c_fyrdScripts;
	mapping (uint256 => string[]) public c_externalScripts;
	mapping (uint256 => bool) public c_locked;

	uint public feePercent;
	address public feeAddress;
	uint constant PERCENT_BASE = 10000;

	address public ownPref;
	bool public pausedPref;

	function initialize(string memory _desc, string memory _token, uint256 _price, uint256 _maxTotal, uint256 _maxMint, uint _feePercent, address _feeAddress, address _gyve, address _ownPref) public initializer {
		__Ownable_init();
		__ERC721Enumerable_init();
		__ERC721_init(_desc, _token);
		price = _price;
		maxMint = _maxMint;
		maxTotal = _maxTotal;
		feePercent = _feePercent;
		feeAddress = _feeAddress;
		ownPref = _ownPref;
		handler = IHandler(_gyve);
		paused = true;
		pausedPref = true;
		scripts.push('holder');
	}

	function _getScripts(string[] storage _scripts) internal view returns (bytes memory script) {
		string[8] memory s;
		for (uint i = 0; i < _scripts.length; i++) {
			uint idx = i % 8;
			s[idx] = _scripts[idx];
		}
		return abi.encodePacked(s[0], s[1], s[2], s[3], s[4], s[5], s[6], s[7]);
	}

	function _allowGetScripts(uint tokenId) internal view returns(bool) {
		return allowCustom && c_scripts[tokenId].length > 0 && !c_locked[tokenId];
	}

	function _getGyveScript(uint256 tokenId) internal view returns (bytes memory script) {
		string[] storage _scripts =  _allowGetScripts(tokenId) ? c_scripts[tokenId] : scripts; 
		return _getScripts(_scripts);
	}

	function _getFyrdScripts(uint256 tokenId) internal view returns (string[] memory script) {
		return _allowGetScripts(tokenId) ? c_fyrdScripts[tokenId] : fyrdScripts;
	}

	function _getExternalScript(uint256 tokenId) internal view returns (bytes memory script) {
		string[] storage _externalScripts = _allowGetScripts(tokenId) ? c_externalScripts[tokenId] : externalScripts; 
		return _getScripts(_externalScripts);
	}

	function _setScripts(string[] storage set, string[] memory _scripts) internal {
		for (uint i = 0; i < _scripts.length; i++) {
			set.push(_scripts[i]);
		}
	}

	function _isOwner() internal view returns(bool) {
		return owner() == _msgSender();
	}

	function _onlyOwner() internal view {
    require(_isOwner(), "!owner");
	}

	function setScripts(string[] memory _scripts) external {
		_onlyOwner();
		delete scripts;
		_setScripts(scripts, _scripts);
	}

	function resetScripts() external {
		_onlyOwner();
		delete scripts;
	}

	function getScripts() external view returns (string[] memory) {
		return scripts;
	}

	function lockCustom(uint tokenId, bool lock) external {
		_onlyOwner();
		c_locked[tokenId] = lock;
	}

	function setAllowCustom(bool _allow) external {
		_onlyOwner();
		allowCustom = _allow;
	}

	function _isCustomAllowed(uint tokenId) internal view returns(bool) {
		return allowCustom && _ownsToken(tokenId) && !c_locked[tokenId];
	}

	function _onlyOwnerOrCustom(uint tokenId) internal view {
		require(_isOwner() || _isCustomAllowed(tokenId), 'custom');
	}

	function setCustomScripts(uint256 tokenId, string[] memory _scripts) external {
		_onlyOwnerOrCustom(tokenId);
		delete c_scripts[tokenId];
		_setScripts(c_scripts[tokenId], _scripts);
	}

	function resetCustomScripts(uint tokenId) external {
		_onlyOwnerOrCustom(tokenId);
		delete c_scripts[tokenId];
	}

	function getCustomScripts(uint256 tokenId) external view returns (string[] memory) {
		return c_scripts[tokenId];
	}

	function setCustomExternalScripts(uint tokenId, string[] memory _scripts) external {
		_onlyOwnerOrCustom(tokenId);
		delete c_externalScripts[tokenId];
		_setScripts(c_externalScripts[tokenId], _scripts);
	}

	function resetCustomExternalScripts(uint tokenId) external {
		_onlyOwnerOrCustom(tokenId);
		delete c_externalScripts[tokenId];
	}

	function getCustomExternalScripts(uint tokenId) external view returns (string[] memory) {
		return c_externalScripts[tokenId];
	}

	function setExternalScripts(string[] memory _scripts) external {
		_onlyOwner();
		delete externalScripts;
		for (uint i = 0; i < _scripts.length; i++) {
			externalScripts.push(_scripts[i]);
		}
	}

	function resetExternalScripts() external {
		_onlyOwner();
		delete externalScripts;
	}

	function getExternalScripts() external view returns (string[] memory) {
		return externalScripts;
	}

	function lenExternalScripts() external view returns(uint) {
		return externalScripts.length;
	}

	function setCustomFyrdScripts(uint tokenId, string[] memory _scripts) external {
		_onlyOwnerOrCustom(tokenId);
		delete c_fyrdScripts[tokenId];
		_setScripts(c_fyrdScripts[tokenId], _scripts);
	}

	function getCustomFyrdScripts(uint tokenId) external view returns (string[] memory) {
		return c_fyrdScripts[tokenId];
	}

	function resetCustomFyrdScripts(uint tokenId) external {
		_onlyOwnerOrCustom(tokenId);
		delete c_fyrdScripts[tokenId];
	}

	function setFyrdScripts(string[] memory _scripts) external {
		_onlyOwner();
		delete fyrdScripts;
		for (uint i = 0; i < _scripts.length; i++) {
			fyrdScripts.push(_scripts[i]);
		}
	}

	function getFyrdScripts() external view returns (string[] memory) {
		return fyrdScripts;
	}

	function resetFyrdScripts() external {
		_onlyOwner();
		delete fyrdScripts;
	}

	function lenFyrdScripts() external view returns(uint) {
		return fyrdScripts.length;
	}

	function tokenURI(uint256 tokenId) override public view returns (string memory) {
		uint256 seed = seeds[tokenId];
		if (seed == 0) return "";
		string memory gyve = string(_getGyveScript(tokenId));
		string memory ext = string(_getExternalScript(tokenId));
		string[] memory fyrd = _getFyrdScripts(tokenId);
		return tokenURI(tokenId, seed, gyve, ext, fyrd, false);
	}

  function stringJoin(bytes[] memory svec, string memory sep, uint vlen) internal pure returns(bytes memory) {
		bytes memory bsep = bytes(sep);
		uint lsep = bsep.length;
		uint len = lsep * (svec.length - 1);
		for (uint i = 0; i < vlen; i++)
			len += bytes(svec[i]).length;

		uint offset = 0;
		bytes memory buff = new bytes(len);
		uint to = Memory.dataPtr(buff);
		uint asep = Memory.dataPtr(bsep);
		for (uint i = 0; i < vlen; i++) {
			bytes memory b = bytes(svec[i]);
			uint slen = b.length;
			uint from = Memory.dataPtr(b);
			Memory.copy(from, to + offset, slen);
			offset += slen;
			if (i < vlen - 1 && lsep > 0) {
				Memory.copy(asep, to + offset, lsep);
				offset += lsep;
			}
		}
		return buff;
	}

	function generateStreams(bytes[MAX_STREAMS] memory streams) internal pure returns (bytes memory) {
		uint16 stream = 0;
		bytes[] memory used = new bytes[](MAX_STREAMS);
		for (uint16 i = 0; i < MAX_STREAMS; i++) {
			if (streams[i].length > 0)
				used[stream++] = streams[i];
		}
		return stringJoin(used, "", stream);
	}

	function generateImage(Result memory vars) internal pure returns (bytes memory) {
		bytes memory svg = generateStreams(vars.streams);
		string memory image = vars.b64Image ? Base64.encode(svg) : string(svg);
		return abi.encodePacked(',"image": "', vars.imagePrefix, image, '"');
	}

	function generateHtml(Result memory vars) internal pure returns (bytes memory) {
		bytes memory html = generateStreams(vars.htmlStreams);
		if (html.length == 0) return html;
		string memory h = vars.b64Html ? Base64.encode(html) : string(html);
		return abi.encodePacked(',"', vars.htmlName, '":"', vars.htmlPrefix, h, '"');
	}

	function generateJson(Result memory vars, bool debug) internal pure returns (string memory) {
		bytes memory image = generateImage(vars);
		bytes memory attrs = generateAttrs(vars);
		bytes memory meta = generateMeta(vars);
		bytes memory html = generateHtml(vars);
		bytes memory name = abi.encodePacked(vars.name, ' #', StringsUpgradeable.toString(vars.tokenId));
		bytes[8] memory json;
		json[0] = abi.encodePacked('{"name":"', name, '","description":"', vars.description, '",', meta, attrs);
		json[1] = image;
		json[2] = html;
		if (debug) {
			json[3] = ',';
			json[4] = generateErrors(vars);
			json[5] = ',';
			json[6] = generatePrints(vars);
			json[7] = generateSlots(vars);
		}
		string memory b64 = Base64.encode(abi.encodePacked(json[0], json[1], json[2], json[3], json[4], json[5], json[6], json[7], '}'));
		return string(abi.encodePacked('data:application/json;base64,', b64));
	}

	function generatePrints(Result memory vars) internal pure returns(bytes memory) {
		bytes[3] memory attrs;
		attrs[0] = '[';
		attrs[1] = '';
		for (uint16 i = 0; i < vars.printSlot; i++) {
			string memory comma = i < vars.printSlot - 1 ? ',' : '';
			attrs[1] = abi.encodePacked(attrs[1], '"', vars.printSlots[i], '"', comma);
		}
		attrs[2] = ']';
		return abi.encodePacked('"prints":', attrs[0], attrs[1], attrs[2]);
	}

	function generateSlots(Result memory vars) internal pure returns(bytes memory) {
		return abi.encodePacked(',"slots":"', Strings.toString(uint(vars.slots)), '"');
	}

			function generateErrors(Result memory vars) internal pure returns(bytes memory) {
				bytes[3] memory attrs;
				attrs[0] = '[';
				attrs[1] = '';
				for (uint8 i = 0; i < vars.errors; i++) {
					string memory comma = i < vars.errors - 1 ? ',' : '';
					attrs[1] = abi.encodePacked(attrs[1], '"', vars.lastErrors[i], '"', comma);
				}
				attrs[2] = ']';
				return abi.encodePacked('"errors":', attrs[0], attrs[1], attrs[2]);
			}

			function generateMeta(Result memory vars) internal pure returns(bytes memory) {
				bytes[] memory attrs = new bytes[](vars.meta);
				for (uint8 i = 0; i < vars.meta; i++) {
					attrs[i] = abi.encodePacked('"', vars.metaNames[i], '":"', vars.metaValues[i], '",');
				}
				return stringJoin(attrs, "", vars.meta);
			}

			function generateAttrs(Result memory vars) internal pure returns(bytes memory) {
				bytes[] memory attrs = new bytes[](MAX_ATTRS * 5 + 5);
				uint idx = 0;
				attrs[idx++] = '"attributes": [';
				for (uint8 i = 0; i < vars.attrs; i++) {
					attrs[idx++] = '{ "trait_type":"';
					attrs[idx++] = bytes(vars.attrTraits[i]);
					attrs[idx++] = '", "value": "';
					attrs[idx++] = bytes(vars.attrValues[i]);
					attrs[idx++] = '" },';
				}
				attrs[idx++] = '{ "trait_type": "Gyve", "value": "';
				attrs[idx++] = '1.0.0';
				attrs[idx++] = '" }';
				attrs[idx++] = ']';
				return stringJoin(attrs, "", idx);
			}

			function mint(uint256 amount) payable external {
				require(paused == false, 'paused');
				_mint(amount, price);
			}

			function mintOwner(uint256 amount) payable external {
				_onlyOwner();
				_mint(amount, price);
			}

			function mintPref1155(uint256 amount, uint256 tokenId) payable external {
				require(pausedPref == false || paused == false, 'paused');
				require(_owns1155(ownPref, tokenId, msg.sender), '!owner');
				uint256 discount = discounts[ownPref];
				if (discount > price)
					discount = price;
				uint _price = discount > 0 ? discount : price;
				_mint(amount, _price);
			}

			function mintPref(uint256 amount) payable external {
				require(pausedPref == false || paused == false, 'paused');
				require(_owns(ownPref, msg.sender), '!owner');
				uint256 discount = discounts[ownPref];
				if (discount > price)
					discount = price;
				uint _price = discount > 0 ? discount : price;
				_mint(amount, _price);
			}

			function mintDiscount1155(uint256 amount, address erc1155, uint256 tokenId) payable external {
				require(paused == false, 'paused');
				uint256 discount = discounts[erc1155];
				require(discount > 0, '!discount');
				require(_owns1155(erc1155, tokenId, msg.sender), '!owner');
				if (discount > price)
					discount = price;
				_mint(amount, discount);
			}

			function mintDiscount(uint256 amount, address erc721) payable external {
				require(paused == false, 'paused');
				uint256 discount = discounts[erc721];
				require(discount > 0, '!discount');
				require(_owns(erc721, msg.sender), '!owner');
				if (discount > price)
					discount = price;
				_mint(amount, discount);
			}

			function _mint(uint256 amount, uint256 thePrice) internal {
				require(amount > 0 && amount <= maxMint, '!amount');
				require(totalSupply() + amount <= maxTotal, '!noneLeft');
				require(msg.value == amount * thePrice, '!price');
				_sendEth(msg.value);
				for (uint256 i = 0; i < amount; i++) {
					_mintToken();
				}
			}

			function _mintToken() internal returns(uint256 tokenId) {
				_tokenIds.increment();
				tokenId = _tokenIds.current();
				_mint(msg.sender, tokenId);
				seeds[tokenId] = _getRandomValue(tokenId);
			}

			function _getRandomValue(uint256 tokenId) internal view returns(uint256) {
				return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender, tokenId)));
			}

			function _owns(address erc721, address _owner) internal view returns(bool) {
				return IERC721Upgradeable(erc721).balanceOf(_owner) > 0;
			}

			function _owns1155(address erc1155, uint256 _tokenId, address _owner) internal view returns(bool) {
				return IERC1155Upgradeable(erc1155).balanceOf(_owner, _tokenId) > 0;
			}

			function _ownsToken(uint tokenId) internal view returns(bool) {
				return ownerOf(tokenId) == msg.sender;
			}

			function setDiscount(address erc721, uint256 discount) external {
				_onlyOwner();
				require(erc721 != address(0), '!erc721');
				discounts[erc721] = discount;
			}

			function unpause() external {
				_onlyOwner();
				paused = false;
			}

			function pause() external {
				_onlyOwner();
				paused = true;
			}

			function unpausePref() external {
				_onlyOwner();
				pausedPref = false;
			}

			function pausePref() external {
				_onlyOwner();
				pausedPref = true;
			}

			function setOwnPref(address _ownPref) external {
				_onlyOwner();
				ownPref = _ownPref;
			}

			function _sendEth(uint256 eth) internal {
				if (eth > 0) {
					uint fee = eth * feePercent / PERCENT_BASE;
					if (fee > 0)
						_send(feeAddress, fee);
					_send(owner(), eth - fee);
				}
			}

			function _send(address dest, uint eth) internal {
				(bool success, ) = dest.call{value: eth}("");
				require(success, '!_send');
			}

			function setHandler(address _handler) external {
				_onlyOwner();
				require(_handler != address(0), '!handler');
				handler = IHandler(_handler);
			}

			function setPrice(uint256 _price) external {
				_onlyOwner();
				price = _price;
			}

			function setMaxTotal(uint256 _maxTotal) external {
				_onlyOwner();
				maxTotal = _maxTotal;
			}

			function tokenURIDebug(uint256 tokenId, uint256 seed, string memory gyve, string memory ext, string[] memory fyrd) external view returns (string memory) {
				_onlyOwnerOrCustom(tokenId);
				return tokenURI(tokenId, seed, gyve, ext, fyrd, true);
			}

			function tokenURI(uint256 tokenId, uint256 seed, string memory gyve, string memory ext, string[] memory fyrd, bool debug) internal view returns (string memory) {
				Result memory result = handler.run(tokenId, seed, gyve, ext, fyrd);
				return generateJson(result, debug);
			}

		}
