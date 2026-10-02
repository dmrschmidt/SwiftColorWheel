import SwiftColorWheel

extension HSBColor {
    /// `#RRGGBB`.
    var hex: String {
        let (red, green, blue) = bytes
        return "#" + [red, green, blue].map { String($0, radix: 16, uppercase: true) }.map { $0.count < 2 ? "0" + $0 : $0 }.joined()
    }

    /// The nearest of a couple of hundred everyday colour names, by "redmean" distance: it
    /// tracks the eye better than plain RGB and needs no colour-space conversion.
    var name: String {
        let (red, green, blue) = bytes
        func miss(_ named: NamedColor) -> Int {
            let mean = (red + named.red) / 2, r = red - named.red, g = green - named.green, b = blue - named.blue
            return (512 + mean) * r * r / 256 + 4 * g * g + (767 - mean) * b * b / 256
        }
        return NamedColor.all.min { miss($0) < miss($1) }?.name ?? ""
    }

    private var bytes: (Int, Int, Int) {
        let rgb = rgb
        return (Int((rgb.red * 255).rounded()), Int((rgb.green * 255).rounded()), Int((rgb.blue * 255).rounded()))
    }
}

private struct NamedColor {
    var name: String
    var red: Int, green: Int, blue: Int

    static let all: [NamedColor] = table.split(whereSeparator: { $0 == "," || $0.isNewline }).compactMap { entry in
        guard let space = entry.lastIndex(of: " "), let hex = Int(entry[entry.index(after: space)...], radix: 16) else { return nil }
        return NamedColor(name: String(entry[..<space]), red: hex >> 16, green: hex >> 8 & 255, blue: hex & 255)
    }

    private static let table = """
        White ffffff,Ivory fffff0,Cream fffdd0,Linen faf0e6,Bone e3dac9,Pearl eae0c8,Silver c0c0c0,Ash b2beb5,Dove 9e9e9e,Grey 808080,Slate 708090,Charcoal 36454f,Onyx 353839,Jet 1b1b1b,Noir 0b0b0b
        Red ff0000,Scarlet ff2400,Vermilion e34234,Crimson dc143c,Ruby e0115f,Cardinal c41e3a,Carmine 960018,Poppy e35335,Tomato ff6347,Coral ff7f50,Salmon fa8072,Brick b22222,Rust b7410e,Oxblood 4a0000,Burgundy 800020,Maroon 800000,Wine 722f37,Garnet 733635
        Pink ffc0cb,Blush f7cfd3,Rose ff007f,Hot Pink ff69b4,Fuchsia f400a1,Magenta ff00ff,Cerise de3163,Raspberry e30b5d,Flamingo fc8eac,Carnation ffa6c9,Dusty Rose c08081,Puce cc8899,Mulberry c54b8c,Berry 990f4b,Peony f2a2c0
        Orange ff7f00,Tangerine f28500,Amber ffbf00,Apricot fbceb1,Peach ffdab9,Melon febaad,Pumpkin ff7518,Persimmon ec5800,Burnt Orange cc5500,Terracotta e2725b,Copper b87333,Bronze cd7f32,Ginger b06500,Cinnamon d2691e,Sienna a0522d,Chestnut 954535,Mahogany 6b2d1a
        Chocolate 7b3f00,Coffee 6f4e37,Espresso 3c2218,Umber 635147,Mocha 967969,Tan d2b48c,Camel c19a6b,Caramel c68642,Sand c2b280,Beige f5f5dc,Khaki c3b091,Taupe 8b7e74
        Yellow ffff00,Lemon fff44f,Canary ffef00,Butter ffef9f,Vanilla f3e5ab,Champagne f7e7ce,Gold ffd700,Mustard e1ad01,Ochre cc7722,Saffron f4c430,Honey eba937,Maize fbec5d,Straw e4d96f,Brass b5a642,Citron c9c62a,Olive 808000
        Lime bfff00,Chartreuse 7fff00,Neon Green 39ff14,Green 00ff00,Kelly 4cbb17,Emerald 50c878,Malachite 0bda51,Jade 00a86b,Shamrock 009e60,Mint 98ff98,Pistachio 93c572,Sage 9caf88,Celadon ace1af,Seafoam 9fe2bf,Spring 00ff7f,Pear d1e231,Apple 8db600,Avocado 568203,Moss 8a9a5b,Fern 4f7942,Army 4b5320,Forest 228b22,Hunter 355e3b,Evergreen 05472a,Bottle 006a4e,Pine 01796f
        Cyan 00ffff,Aquamarine 7fffd4,Turquoise 40e0d0,Lagoon 04a3b6,Teal 008080,Petrol 005f6a,Peacock 1f7a8c,Ice dff6ff,Duck Egg c3e3dc,Powder b0e0e6,Sky 87ceeb,Capri 00bfff
        Azure 007fff,Blue 0000ff,Cobalt 0047ab,Royal 4169e1,Ultramarine 2a2fd4,Sapphire 0f52ba,Cerulean 007ba7,Denim 1560bd,Steel 4682b4,Cornflower 6495ed,Baby Blue 89cff0,Periwinkle ccccff,Navy 000080,Midnight 191970,Prussian 003153,Indigo 4b0082
        Violet 8f00ff,Purple 800080,Grape 6f2da8,Iris 5a4fcf,Amethyst 9966cc,Heliotrope df73ff,Orchid da70d6,Mauve e0b0ff,Wisteria c9a0dc,Lilac c8a2c8,Lavender d8c8f5,Thistle d8bfd8,Plum 8e4585,Byzantium 702963,Aubergine 3b0a3f
        """
}
