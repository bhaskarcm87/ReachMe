import UIKit
import PlaygroundSupport

class Poster: UIView {
    
    var text: String? {
        didSet {
            textLabel?.text = text
        }
    }
    
    private var textLabel: UILabel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        didLoad()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        didLoad()
    }
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    func didLoad() {
        textLabel = UILabel()
        textLabel?.textColor = .red
        textLabel?.textAlignment = .center
        textLabel?.font = UIFont.boldSystemFont(ofSize: 20.0)
        textLabel?.frame = frame
        addSubview(textLabel!)
        
        layer.cornerRadius = frame.height / 2
        backgroundColor = .blue
    }
}

class Hero {
    var name: String
    var mainSuperPower: String
    var superPowers: [String]
    
    init(name: String, mainPower: String) {
        self.name = name
        self.mainSuperPower = mainPower
        
        superPowers = [String]()
        superPowers.append(mainPower)
    }
}

extension Hero: CustomPlaygroundDisplayConvertible {
    var playgroundDescription: Any {
        let poster = Poster(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 34)))
        poster.text = name
        return poster
    }
}

let thor = Hero(name: "Sachin", mainPower: "Thunder")
let ironMan = Hero(name: "Bapi", mainPower: "Brain")

let temp = "hello"
