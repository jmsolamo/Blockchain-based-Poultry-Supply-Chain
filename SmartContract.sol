// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PoultrySupplyChain {
    enum Status { Created, InTransit, Delivered }

    struct Product {
        uint id;
        string name;
        uint quantity;
        string origin;
        uint dateCreated;
        address currentOwner;
        Status status;
    }

    uint public nextProductId = 1;
    mapping(uint => Product) public products;
    mapping(uint => address[]) public ownershipHistory;

    address public admin;
    mapping(address => bool) public farmers;
    mapping(address => bool) public distributors;

    // Events
    event ProductRegistered(uint productId, address owner);
    event OwnershipTransferred(uint productId, address from, address to, Status status);
    event StatusUpdated(uint productId, Status status);

    modifier onlyFarmer() {
        require(farmers[msg.sender], "Not an authorized farmer");
        _;
    }

    modifier onlyDistributor() {
        require(distributors[msg.sender], "Not an authorized distributor");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // Admin functions to add authorized users
    function addFarmer(address _farmer) external {
        require(msg.sender == admin, "Only admin can add farmers");
        farmers[_farmer] = true;
    }

    function addDistributor(address _distributor) external {
        require(msg.sender == admin, "Only admin can add distributors");
        distributors[_distributor] = true;
    }

    // Product registration
    function registerProduct(
        string memory _name,
        uint _quantity,
        string memory _origin
    ) external onlyFarmer {
        uint productId = nextProductId;
        products[productId] = Product({
            id: productId,
            name: _name,
            quantity: _quantity,
            origin: _origin,
            dateCreated: block.timestamp,
            currentOwner: msg.sender,
            status: Status.Created
        });

        ownershipHistory[productId].push(msg.sender);
        nextProductId++;

        emit ProductRegistered(productId, msg.sender);
    }

    // Transfer ownership from farmer to distributor
    function transferOwnership(uint _productId, address _to) external {
        Product storage product = products[_productId];
        require(msg.sender == product.currentOwner, "Only current owner can transfer");

        if(farmers[msg.sender]) {
            require(distributors[_to], "Can only transfer to distributor");
            product.status = Status.InTransit;
        } else if(distributors[msg.sender]) {
            product.status = Status.Delivered;
        }

        ownershipHistory[_productId].push(_to);
        address previousOwner = product.currentOwner;
        product.currentOwner = _to;

        emit OwnershipTransferred(_productId, previousOwner, _to, product.status);
        emit StatusUpdated(_productId, product.status);
    }

    // Data retrieval
    function getProduct(uint _productId) external view returns (Product memory) {
        return products[_productId];
    }

    function getOwnershipHistory(uint _productId) external view returns (address[] memory) {
        return ownershipHistory[_productId];
    }

    function getProductStatus(uint _productId) external view returns (Status) {
        return products[_productId].status;
    }
}