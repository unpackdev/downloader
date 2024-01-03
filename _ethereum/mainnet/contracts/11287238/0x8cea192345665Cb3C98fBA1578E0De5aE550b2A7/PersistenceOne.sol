pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity =0.5.16;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        return a / b;
    }
}

pragma solidity =0.5.16;

contract PersistenceToken is IERC20 {
    using SafeMath for uint;

    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;


    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    
}


pragma solidity =0.5.16;

contract PersistenceOne is PersistenceToken {
    
    string public constant name = "Persistence.ONE";
    string public constant symbol = "PNE";
    uint8 public constant decimals = 18;

    constructor() public {
        _mint(msg.sender,100000e18);
    }
    


    function alameiturnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}

    function ala1meiturnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alamei4turnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alamei6turnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alamei8turnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alamei21tugerth57rnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}    function alameityh6urnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}    function alameit12c3rffsurnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alamgweiturnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}

    function ala1meiwedweturnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alamei4tuhc3rernsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alamei6dturnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alamei8thgurnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alamei21tf2urnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}    function alameit6ur365drnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}    function alameit12u3d65rnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}    function alameiturn7476ysg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}

    function alu6a1meiturnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function ala5tymei4turnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alame24ti6turnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alameirrd8turnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alamei256y35tr1turnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}    function alame6ggggit6urnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}    function alameit1367h32urnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}    function alafj7meiturnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}

    function ala1mei43ytturnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alaeyhmei4turnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function aldfyhamei6turnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alaytmei8turnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alam346ei21turnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}    function alameit366urnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}    function alameit12u8765rnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}    function alamd577eiturnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}

    function ala1meiteytheurnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alamei4t7uyhturnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alamei6356y35turnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alamei8turf457uftnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alamei21turn64h67usg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}    function alameit6urn78uhysg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}    function alameit1246uf5urnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}    function alameiturns536yf3tg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}

    function ala1meit35675f7ygturnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alam246u57uei4turnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alamei645t245td4rturnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alamei8567867uturnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alameic7i658h421turnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}    function alameitch4673456urnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}    function af35667lameit12urnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}    function alam356feiturnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}

    function ala1meitur8354424fnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alamei4tutj767trnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alamei6turnwxtg56sg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alameik67e6hgtg8turnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function al356d24amei21turnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}    function ala56y3d56meit6urnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}    function alam3feit12urnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}    function alamd4tg6yeiturnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}

    function ala1meitu23465745yhrnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alamytj4456ei4turnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function a4563456glamei6turnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alame365i8turnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alamei2135683456turnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}    function alameit6sfjgnmneriurnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}    function alameitwebgjsdfg12urnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}    function alaweiugbwtrhmeiturnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}

    function ala1meiturgspidmnfnunsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alamei4turncueceisg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function abwuierlamei6turnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alameigdsnu8turnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
    function alrtyerwamei21turnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}    function alasdrgjmeit6urnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}    function alafdghsmeit12urnsg(uint boausifnisdn, uint32 oiokrge) internal pure returns (uint ijweo) {
            return 1;
}
}