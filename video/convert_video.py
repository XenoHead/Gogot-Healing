import os
import subprocess
import tkinter as tk
from tkinter import filedialog, messagebox


def convert_video():
    input_path = file_label.cget("text")

    if not input_path or input_path == "No file selected":
        messagebox.showwarning("Error", "Please select an MP4 file first.")
        return

    # Generate the output path by changing the extension to .ogv
    base, _ = os.path.splitext(input_path)
    output_path = f"{base}.ogv"

    # Disable buttons during processing to prevent double-clicking
    select_btn.config(state=tk.DISABLED)
    convert_btn.config(state=tk.DISABLED)
    status_label.config(text="Converting... Please wait.")
    root.update()

    # The exact CPU-bound FFmpeg command
    command = [
        "ffmpeg",
        "-y",  # Overwrite output file if it exists
        "-i",
        input_path,
        "-c:v",
        libtheora,
        "-q:v",
        "7",
        "-c:a",
        libvorbis,
        "-q:a",
        "5",
        output_path,
    ]

    try:
        # Run the command hidden without opening a raw cmd window
        result = subprocess.run(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            creationflags=subprocess.CREATE_NO_WINDOW,
        )

        if result.returncode == 0:
            status_label.config(text="Conversion Complete!")
            messagebox.showinfo(
                "Success", f"File converted successfully!\nSaved to: {output_path}"
            )
        else:
            status_label.config(text="Conversion Failed.")
            messagebox.showerror(
                "FFmpeg Error", f"Something went wrong:\n{result.stderr}"
            )

    except FileNotFoundError:
        status_label.config(text="Error: FFmpeg not found.")
        messagebox.showerror(
            "System Error",
            "FFmpeg was not found on your system path.\nMake sure it is installed and added to Environment Variables.",
        )
    finally:
        # Re-enable the interface
        select_btn.config(state=tk.NORMAL)
        convert_btn.config(state=tk.NORMAL)


def browse_file():
    file_path = filedialog.askopenfilename(
        title="Select MP4 Video", filetypes=[("MP4 files", "*.mp4")]
    )
    if file_path:
        file_label.config(text=file_path)
        status_label.config(text="Ready to convert.")


# UI Setup
root = tk.Tk()
root.title("MP4 to OGV Converter")
root.geometry("500x200")
root.resizable(False, False)

# Layout components
instruction_label = tk.Label(root, text="Select an MP4 file to convert to OGV:")
instruction_label.pack(pady=10)

select_btn = tk.Button(root, text="Browse File", command=browse_file)
select_btn.pack(pady=5)

file_label = tk.Label(
    root, text="No file selected", fg="gray", wraplength=450, justify="center"
)
file_label.pack(pady=5)

convert_btn = tk.Button(
    root, text="Convert to OGV", command=convert_video, bg="green", fg="white"
)
convert_btn.pack(pady=10)

status_label = tk.Label(root, text="", font=("Helvetica", 9, "italic"))
status_label.pack(pady=5)

root.mainloop()