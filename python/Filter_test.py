import pandas as pd
import matplotlib.pyplot as plt
from scipy.signal import firwin, lfilter
import ipywidgets as widgets
from IPython.display import display

# 加载 CSV 文件
df = pd.read_csv("uart_ready_output.csv")
df.columns = ['time', 'value']  # 确保列名一致

# 主函数
def apply_filters(ma_window, fir_cutoff):
    time = df['time'].values
    signal = df['value'].values

    # Moving Average
    ma_filtered = pd.Series(signal).rolling(window=ma_window, min_periods=1, center=True).mean()

    # FIR Filter
    fir_coeff = firwin(numtaps=ma_window, cutoff=fir_cutoff, fs=1 / (time[1] - time[0]), pass_zero=True)
    fir_filtered = lfilter(fir_coeff, 1.0, signal)

    # 画 3 个 subplot
    fig, axs = plt.subplots(3, 1, figsize=(12, 8), sharex=True)
    
    axs[0].plot(time, signal, label='Original', color='steelblue')
    axs[0].set_ylabel("Original")
    axs[0].grid(True)
    
    axs[1].plot(time, ma_filtered, label=f'MA (window={ma_window})', color='darkorange')
    axs[1].set_ylabel("MA")
    axs[1].grid(True)
    
    axs[2].plot(time, fir_filtered, label=f'FIR (cutoff={fir_cutoff:.2f})', color='forestgreen')
    axs[2].set_ylabel("FIR")
    axs[2].set_xlabel("Time")
    axs[2].grid(True)

    fig.suptitle("Filter Comparison")
    plt.tight_layout()
    plt.show()

# 滑条控件
ma_slider = widgets.IntSlider(value=5, min=1, max=51, step=2, description='MA Window')
fir_slider = widgets.FloatSlider(value=0.05, min=0.01, max=0.5, step=0.01, description='FIR Cutoff')

ui = widgets.VBox([ma_slider, fir_slider])
out = widgets.interactive_output(apply_filters, {'ma_window': ma_slider, 'fir_cutoff': fir_slider})

display(ui, out)
