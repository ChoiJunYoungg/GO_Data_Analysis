import os
import pandas as pd
from sgfmill import sgf

input_folder = "C:/GO_GIBO"  
output_file = "go_games_bronze.csv"

all_games = []

for filename in os.listdir(input_folder):
    if filename.endswith(".sgf") or filename.endswith(".txt"):
        file_path = os.path.join(input_folder, filename)       
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()

            game = sgf.Sgf_game.from_string(content)
            root = game.get_root()
            game_info = {
                    "흑": root.get("PB"),  
                    "백": root.get("PW"),
                    "덤": root.get("KM"),
                    "결과": root.get("RE"),
                    "대국일자": root.get("DT"),
                    "대국명": root.get("GN"),
                    "제한시간": root.get("TM"),
                    "초읽기 횟수": root.get("TC"),
                    "초읽기 시간": root.get("TT"),
                    "대국룰": root.get("RU"),
                    "흑번국가": root.get("BC"),
                    "백번국가": root.get("WC")               
                }
            all_games.append(game_info)
         


df_bronze = pd.DataFrame(all_games)
df_bronze.to_csv(output_file, index=False, encoding="utf-8")
print(f"총 {len(df_bronze)}개의 대국 데이터가 {output_file}로 저장되었습니다.")
