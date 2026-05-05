// SPDX-License-Identifier: AGPL-3.0-only

import { Box, Text, useInput } from "ink";
import { useEffect, useMemo, useState } from "react";
import Footer from "../components/Footer";
import { Spinner, StatusMessage, TextInput } from "../components/ui";
import { authClient } from "../lib/auth-client";
import { COLORS } from "../lib/colors";

interface Props {
	email: string;
	onVerified: () => void;
	onBack: () => void;
}

type OtpMode = "input" | "verifying" | "success";

export default function VerifyOtpScreen({ email, onVerified, onBack }: Props) {
	const [mode, setMode] = useState<OtpMode>("input");
	const [focusedIndex, setFocusedIndex] = useState(0);
	const [otp, setOtp] = useState("");
	const [error, setError] = useState("");

	const fieldCount = 2; // otp input, submit button

	useInput((_input, key) => {
		if (mode === "verifying" || mode === "success") return;

		if (key.escape) {
			onBack();
			return;
		}

		if (key.tab) {
			const dir = key.shift ? -1 : 1;
			setFocusedIndex((i) => (i + dir + fieldCount) % fieldCount);
			return;
		}

		if (key.return && focusedIndex === fieldCount - 1) {
			handleSubmit();
		}
	});

	useEffect(() => {
		if (mode !== "success") return;
		const timer = setTimeout(onVerified, 1500);
		return () => clearTimeout(timer);
	}, [mode, onVerified]);

	const handleSubmit = async () => {
		if (!otp.trim()) {
			setError("Enter the verification code");
			setFocusedIndex(0);
			return;
		}

		setError("");
		setMode("verifying");

		try {
			const { error: verifyError } = await authClient.emailOtp.verifyEmail({
				email,
				otp: otp.trim(),
			});

			if (verifyError) {
				throw new Error(
					verifyError.message || "Invalid code — check and try again",
				);
			}

			setMode("success");
		} catch (err) {
			setError(
				err instanceof Error ? err.message : "Verification failed — try again",
			);
			setMode("input");
			setOtp("");
		}
	};

	const footerShortcuts = useMemo(
		() => [
			{ key: "Tab", action: "Next" },
			{ key: "Enter", action: "Submit" },
			{ key: "Esc", action: "Back" },
		],
		[],
	);

	return (
		<Box flexDirection="column" width="100%" flexGrow={1} paddingX={1}>
			<Box
				flexGrow={1}
				flexDirection="column"
				justifyContent="center"
				alignItems="center"
				paddingY={1}
			>
				{mode === "verifying" ? (
					<Box
						flexDirection="column"
						borderStyle="single"
						borderColor={COLORS.ACCENT}
						paddingX={3}
						paddingY={1}
					>
						<Spinner label="Verifying..." />
					</Box>
				) : mode === "success" ? (
					<Box
						flexDirection="column"
						borderStyle="single"
						borderColor={COLORS.SUCCESS}
						paddingX={3}
						paddingY={1}
					>
						<Text bold color={COLORS.SUCCESS}>
							Email verified
						</Text>
						<Text dimColor>You can now log in to your account.</Text>
					</Box>
				) : (
					<Box flexDirection="column" width={50} paddingX={2}>
						<Box marginBottom={1}>
							<Text dimColor>
								A verification code was sent to{" "}
								<Text bold color={COLORS.ACCENT}>
									{email}
								</Text>
							</Text>
						</Box>

						<Box flexDirection="row" alignItems="center">
							<Box width={12}>
								<Text
									color={
										focusedIndex === 0 ? COLORS.ACCENT : COLORS.TEXT_SECONDARY
									}
									bold={focusedIndex === 0}
								>
									Code:
								</Text>
							</Box>
							<Box flexGrow={1}>
								<TextInput
									onChange={setOtp}
									onSubmit={handleSubmit}
									isDisabled={focusedIndex !== 0}
								/>
							</Box>
						</Box>

						<Box marginTop={1} justifyContent="center">
							<Box
								backgroundColor={
									focusedIndex === 1 ? COLORS.ACCENT_BG : COLORS.BORDER
								}
								paddingX={3}
							>
								<Text
									bold={focusedIndex === 1}
									color={
										focusedIndex === 1
											? COLORS.ACCENT_TEXT
											: COLORS.TEXT_SECONDARY
									}
								>
									Verify
								</Text>
							</Box>
						</Box>

						{error && (
							<Box marginTop={1}>
								<StatusMessage variant="error">{error}</StatusMessage>
							</Box>
						)}
					</Box>
				)}
			</Box>

			{mode === "input" && <Footer shortcuts={footerShortcuts} />}
		</Box>
	);
}
